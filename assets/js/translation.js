let translations = null;

function getTranslations() {
  if(translations) return translations;

  const el = document.querySelector('meta[name="hygeia-translations"]');

  if(!el) throw "missing translation meta";

  translations = JSON.parse(el.content);

  return translations;
}

export function translate(msgId) {
  return getTranslations()[msgId];
}