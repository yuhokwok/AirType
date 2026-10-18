// This is a browser-only demonstration. It never contacts an AirType keyboard.
const demoForm = document.querySelector('#demo-form');
const demoText = document.querySelector('#demo-text');
const phoneMessage = document.querySelector('#phone-message');
const demoStatus = document.querySelector('#demo-status');
const demoCopy = document.documentElement.lang.startsWith('en')
  ? { sent: 'Demo complete. Your text is shown on the right.', received: 'Text received' }
  : { sent: '示範完成，文字已出現在右邊。', received: '已接收文字' };
demoForm.addEventListener('submit', event => {
  event.preventDefault();
  const value = demoText.value.trim();
  if (!value) { demoText.focus(); return; }
  phoneMessage.textContent = value;
  phoneMessage.classList.add('received');
  demoStatus.textContent = demoCopy.sent;
  document.querySelector('#phone-status').textContent = demoCopy.received;
  demoText.focus();
});
demoText.addEventListener('keydown', event => {
  if (event.key === 'Enter' && !event.shiftKey && !event.isComposing) {
    event.preventDefault(); demoForm.requestSubmit();
  }
});
document.querySelectorAll('[data-dialog]').forEach(button => {
  button.addEventListener('click', () => document.getElementById(button.dataset.dialog).showModal());
});
document.querySelectorAll('dialog').forEach(dialog => {
  dialog.querySelector('[data-close]').addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => {
    const rect = dialog.getBoundingClientRect();
    if (event.target === dialog && (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom)) dialog.close();
  });
});
