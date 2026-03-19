(function () {
  let initialized = false;
  let menuElement = null;

  function ensureMenu() {
    if (menuElement) {
      return menuElement;
    }
    menuElement = document.createElement('div');
    menuElement.className = 'git-path-context-menu';
    menuElement.hidden = true;
    document.body.appendChild(menuElement);
    return menuElement;
  }

  function hideMenu() {
    const menu = ensureMenu();
    menu.hidden = true;
    menu.innerHTML = '';
  }

  function activateAction(action) {
    if (action.dataset.disabled === 'true') {
      return;
    }
    const link = action.querySelector('a');
    if (link) {
      link.dispatchEvent(new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        view: window
      }));
    }
  }

  function buildMenu(pathItem) {
    const menu = ensureMenu();
    menu.innerHTML = '';
    const actions = pathItem.querySelectorAll('.git-path-context-action');
    actions.forEach(action => {
      const entry = document.createElement('button');
      entry.type = 'button';
      entry.className = 'git-path-context-menu-entry';
      if (action.dataset.disabled === 'true') {
        entry.disabled = true;
      }
      entry.textContent = action.dataset.label || action.textContent.trim();
      entry.addEventListener('click', event => {
        event.preventDefault();
        event.stopPropagation();
        hideMenu();
        activateAction(action);
      });
      menu.appendChild(entry);
    });
    return menu;
  }

  function positionMenu(menu, x, y) {
    menu.style.left = '0px';
    menu.style.top = '0px';
    menu.hidden = false;
    const width = menu.offsetWidth;
    const height = menu.offsetHeight;
    const left = Math.min(x, window.innerWidth - width - 8);
    const top = Math.min(y, window.innerHeight - height - 8);
    menu.style.left = Math.max(8, left) + 'px';
    menu.style.top = Math.max(8, top) + 'px';
  }

  function onContextMenu(event) {
    const pathItem = event.target.closest('.git-path-item');
    if (!pathItem) {
      hideMenu();
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    const menu = buildMenu(pathItem);
    positionMenu(menu, event.clientX, event.clientY);
  }

  function init() {
    if (initialized) {
      return;
    }
    initialized = true;
    ensureMenu();
    document.addEventListener('contextmenu', onContextMenu);
    document.addEventListener('click', hideMenu, true);
    document.addEventListener('keydown', event => {
      if (event.key === 'Escape') {
        hideMenu();
      }
    });
    window.addEventListener('resize', hideMenu);
    window.addEventListener('scroll', hideMenu, true);
  }

  window.hyperdocGitPathContextMenu = {
    init: init,
    hide: hideMenu
  };
})();
