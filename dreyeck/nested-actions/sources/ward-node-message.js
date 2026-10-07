const message = {
  action: 'publishSourceData',
  topic: 'node',
  title: props.title || props.name.replaceAll(/\n/g,' ')
}
window.opener.postMessage(message)
