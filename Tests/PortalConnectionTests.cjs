// Run with node --test Tests/PortalConnectionTests.cjs. Uses the actual bundled portal script.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const vm = require('node:vm');
const { webcrypto } = require('node:crypto');
const html = readFileSync(new URL('../Shared/Resources/Portal.html', `file://${__filename}`), 'utf8');

function portal(hash = '') {
    let time = 0, nextID = 0, mode = 'up';
    const timers = new Map(), calls = [], elements = new Map();
    class Element {
        constructor() { this.hidden = false; this.children = []; this.value = ''; this.textContent = ''; this.disabled = false; }
        setAttribute() {}
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
    vm.runInContext(html.match(/<script>([\s\S]*?)<\/script>/)[1], context);
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
