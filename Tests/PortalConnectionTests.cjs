// Run with node --test Tests/PortalConnectionTests.cjs. Uses the actual bundled portal script.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const vm = require('node:vm');
const { webcrypto } = require('node:crypto');
const html = readFileSync(new URL('../Shared/Resources/Portal.html', `file://${__filename}`), 'utf8');

function portal(hash = '', language = 'en') {
    let time = 0, nextID = 0, mode = 'up';
    const timers = new Map(), calls = [], elements = new Map();
    class Element {
        constructor() { this.hidden = false; this.children = []; this.value = ''; this.textContent = ''; this.disabled = false; this.dataset = {}; this.attributes = {}; this.listeners = {}; }
        setAttribute(name, value) { this.attributes[name] = value; }
        addEventListener(name, callback) { this.listeners[name] = callback; }
        append(element) { this.children.push(element); }
        replaceChildren(...elements) { this.children = elements; }
        focus() {}
        dispatchEvent() {}
    }
    for (const [, id] of html.matchAll(/id="([^"]+)"/g)) elements.set('#' + id, new Element());
    elements.get('#typing').hidden = true;
    const schedule = (callback, delay, interval = false) => {
        const id = ++nextID;
        timers.set(id, { callback, at: time + delay, interval: interval ? delay : 0 });
        return id;
    };
    const context = vm.createContext({
        document: {
            querySelector: selector => elements.get(selector),
            querySelectorAll: () => ['#send', '#delete', '#return'].map(id => elements.get(id)),
            createElement: () => new Element(), createTextNode: value => value, addEventListener() {}
        },
        location: { hash, pathname: '/' }, history: { replaceState() {} },
        Date: class extends Date { static now() { return time; } },
        setTimeout: (fn, delay) => schedule(fn, delay), clearTimeout: id => timers.delete(id),
        setInterval: (fn, delay) => schedule(fn, delay, true), clearInterval: id => timers.delete(id),
        AbortController, crypto: webcrypto, Event,
        addEventListener() {},
        fetch: async (path, options) => {
            calls.push({ path, at: time, body: options.body });
            if (mode === 'hanging') return new Promise((_, reject) => {
                options.signal.addEventListener('abort', () => reject(new Error('aborted')), { once: true });
            });
            if (mode === 'down') throw new Error('offline');
            const rejected = mode === 'denied' || (path === '/pair' && JSON.parse(options.body).code !== '123456');
            return { ok: !rejected, status: rejected ? 403 : 200,
                text: async () => 'Incorrect pairing code',
                json: async () => path === '/pair' ? { token: 'paired-token' } : { connected: true, ok: true } };
        }
    });
    const locales = JSON.parse(readFileSync(new URL('../Shared/Resources/PortalLocales.json', `file://${__filename}`), 'utf8'));
    const script = html.match(/<script>([\s\S]*?)<\/script>/)[1].replace('/*AIRTYPE_I18N*/{}', JSON.stringify(locales[language] ?? {}));
    vm.runInContext(script, context);
    const flush = async () => { for (let i = 0; i < 20; i++) await Promise.resolve(); };
    return {
        el: id => elements.get(id), calls,
        setMode: value => { mode = value; },
        flush,
        async pair(code) { elements.get('#code').value = code; await elements.get('#pair-form').onsubmit({ preventDefault() {} }); await flush(); },
        async tick(duration) {
            const target = time + duration;
            await flush();
            while (true) {
                const next = [...timers.entries()].filter(([, timer]) => timer.at <= target).sort((a,b) => a[1].at - b[1].at)[0];
                if (!next) break;
                const [id, timer] = next; time = timer.at;
                if (timer.interval) timer.at += timer.interval; else timers.delete(id);
                timer.callback(); await flush();
            }
            time = target; await flush();
        }
    };
}

test('pairing and typing are separate steps in one panel; invalid codes keep the pairing step', async () => {
    const page = portal();
    assert.equal(page.el('#typing').hidden, true);
    assert.equal(page.el('#pairing').hidden, false);
    await page.pair('000000');
    assert.equal(page.el('#typing').hidden, true);
    assert.match(page.el('#pair-error').textContent, /Incorrect/);
    await page.pair('123456');
    assert.equal(page.el('#pairing').hidden, true);
    assert.equal(page.el('#typing').hidden, false);
    assert.equal(page.el('#send').disabled, false);
});

test('outage stops requests after 10 seconds, retains drafts, and requires manual reconnect', async () => {
    const page = portal('#valid-token'); await page.flush();
    page.el('#text').value = 'Draft 😀'; page.setMode('down');
    await page.tick(1500); // First unavailable status request starts the 10-second window.
    await page.tick(9999);
    assert.equal(page.el('#reconnect').hidden, true);
    await page.tick(1);
    assert.equal(page.el('#reconnect').hidden, false);
    assert.equal(page.el('#send').disabled, true);
    assert.equal(page.el('#text').value, 'Draft 😀');
    const count = page.calls.length;
    page.setMode('up'); await page.tick(60000);
    assert.equal(page.calls.length, count);
    page.el('#reconnect').onclick(); await page.flush();
    assert.equal(page.el('#reconnect').hidden, true);
    assert.equal(page.el('#send').disabled, false);
    assert.equal(page.el('#text').value, 'Draft 😀');
});

test('a server that never responds also stops after 10 seconds', async () => {
    const page = portal('#valid-token'); await page.flush();
    page.setMode('hanging'); await page.tick(1500);
    await page.tick(10000);
    assert.equal(page.el('#reconnect').hidden, false);
    const count = page.calls.length;
    await page.tick(60000);
    assert.equal(page.calls.length, count);
});

test('a server returning before the deadline reconnects automatically and resets the deadline', async () => {
    const page = portal('#valid-token'); await page.flush();
    page.setMode('down'); await page.tick(4500);
    page.setMode('up'); await page.tick(1500);
    assert.equal(page.el('#send').disabled, false);
    await page.tick(15000);
    assert.equal(page.el('#reconnect').hidden, true);
    assert.equal(page.el('#send').disabled, false);
});

test('expired authorization returns to pairing without losing a draft', async () => {
    const page = portal('#expired-token'); await page.flush();
    page.el('#text').value = 'Keep me'; page.setMode('denied');
    await page.tick(1500);
    assert.equal(page.el('#typing').hidden, true);
    assert.equal(page.el('#pairing').hidden, false);
    assert.equal(page.el('#text').value, 'Keep me');
    const count = page.calls.length; await page.tick(20000);
    assert.equal(page.calls.length, count);
    page.setMode('up'); await page.pair('123456');
    assert.equal(page.el('#typing').hidden, false);
    assert.equal(page.el('#text').value, 'Keep me');
});

async function key(page, key, extra = {}) {
    let prevented = false;
    page.el('#text').onkeydown({ key, preventDefault() { prevented = true; }, ...extra });
    await page.flush();
    return prevented;
}
const commands = page => page.calls.filter(call => call.path === '/command').map(call => JSON.parse(call.body));

test('empty Enter and Backspace send newline and delete to the keyboard', async () => {
    const page = portal('#valid-token'); await page.flush();
    assert.equal(await key(page, 'Enter'), true);
    assert.equal(await key(page, 'Backspace'), true);
    assert.deepEqual(commands(page).map(command => command.action), ['newline', 'delete']);
    assert.ok(commands(page).every(command => command.text === null));
});

test('nonempty drafts send on Enter; Backspace and Shift Enter remain local', async () => {
    const page = portal('#valid-token'); await page.flush();
    page.el('#text').value = '你好 👨‍👩‍👧‍👦';
    assert.equal(await key(page, 'Backspace'), false);
    assert.equal(await key(page, 'Enter', { shiftKey: true }), false);
    assert.equal(commands(page).length, 0);
    assert.equal(await key(page, 'Enter'), true);
    assert.equal(commands(page)[0].text, '你好 👨‍👩‍👧‍👦');
    assert.equal(page.el('#text').value, '');
    page.el('#text').value = ' ';
    await key(page, 'Enter');
    assert.equal(commands(page)[1].action, 'insert');
    assert.equal(commands(page)[1].text, ' ');
});

test('IME composition and command modifiers never send remote edits', async () => {
    const page = portal('#valid-token'); await page.flush();
    for (const extra of [{ isComposing: true }, { keyCode: 229 }, { ctrlKey: true }, { metaKey: true }, { altKey: true }]) {
        assert.equal(await key(page, 'Enter', extra), false);
        assert.equal(await key(page, 'Backspace', extra), false);
    }
    page.el('#text').listeners.compositionstart();
    assert.equal(await key(page, 'Enter'), false);
    page.el('#text').listeners.compositionend();
    assert.equal(commands(page).length, 0);
    await key(page, 'Enter');
    assert.equal(commands(page)[0].action, 'newline');
});

test('disconnected empty-key presses do not send and a failed command is not replayed', async () => {
    const unpaired = portal();
    await key(unpaired, 'Enter'); await key(unpaired, 'Backspace');
    assert.equal(commands(unpaired).length, 0);
    const page = portal('#valid-token'); await page.flush();
    page.setMode('down'); await key(page, 'Enter');
    assert.equal(commands(page).length, 1);
    page.setMode('up'); await page.tick(1500);
    assert.equal(commands(page).length, 1);
});

test('server-selected Chinese localizes pairing, errors, reconnect and emoji search', async () => {
    const page = portal('', 'zh-Hant');
    assert.equal(page.el('#connect').textContent, '連線');
    assert.equal(page.el('#text').attributes.placeholder, '在此輸入⋯');
    assert.equal(page.el('#reconnect').textContent, '重新連線');
    await page.pair('123456');
    assert.equal(page.el('#step').textContent, '2 · 輸入到裝置');
    const categories = page.el('#emoji-categories').children;
    assert.equal(categories[0].textContent, '笑臉');
    page.el('#emoji-search').value = '貓'; page.el('#emoji-search').oninput();
    assert.ok(page.el('#emoji-grid').children.some(button => button.attributes['aria-label'] === '貓'));
    page.setMode('down'); await page.tick(11500);
    assert.match(page.el('#status').children[1], /草稿已保留/);
    const simplified = portal('', 'zh-Hans');
    assert.equal(simplified.el('#connect').textContent, '连接');
    assert.equal(simplified.el('#code').attributes['aria-label'], '配对码');
});
