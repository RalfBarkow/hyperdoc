(function () {
  function setScale(chart, scale) {
    var svg = chart.querySelector("svg");
    if (!svg) {
      return;
    }
    var boundedScale = Math.max(0.4, Math.min(2.5, scale));
    chart.dataset.scxmlArchitectScale = String(boundedScale);
    svg.style.transformOrigin = "top left";
    svg.style.transform = "scale(" + boundedScale + ")";
  }

  function currentScale(chart) {
    var parsed = Number(chart.dataset.scxmlArchitectScale || "1");
    if (!Number.isFinite(parsed) || parsed <= 0) {
      return 1;
    }
    return parsed;
  }

  function bindToolbar(shell) {
    var chart = shell.querySelector("[data-scxml-architect-chart]");
    if (!chart || chart.dataset.scxmlArchitectBound === "true") {
      return;
    }
    chart.dataset.scxmlArchitectBound = "true";
    setScale(chart, 1);

    shell.querySelectorAll("[data-scxml-architect-zoom]").forEach(function (button) {
      button.addEventListener("click", function () {
        var action = button.dataset.scxmlArchitectZoom;
        var scale = currentScale(chart);
        if (action === "in") {
          setScale(chart, scale + 0.15);
          return;
        }
        if (action === "out") {
          setScale(chart, scale - 0.15);
          return;
        }
        setScale(chart, 1);
        chart.scrollTop = 0;
        chart.scrollLeft = 0;
      });
    });

    var panning = {
      active: false,
      x: 0,
      y: 0,
      scrollLeft: 0,
      scrollTop: 0
    };

    chart.addEventListener("mousedown", function (event) {
      if (event.button !== 0) {
        return;
      }
      panning.active = true;
      panning.x = event.clientX;
      panning.y = event.clientY;
      panning.scrollLeft = chart.scrollLeft;
      panning.scrollTop = chart.scrollTop;
      chart.classList.add("is-panning");
      event.preventDefault();
    });

    window.addEventListener("mousemove", function (event) {
      if (!panning.active) {
        return;
      }
      var deltaX = event.clientX - panning.x;
      var deltaY = event.clientY - panning.y;
      chart.scrollLeft = panning.scrollLeft - deltaX;
      chart.scrollTop = panning.scrollTop - deltaY;
    });

    window.addEventListener("mouseup", function () {
      if (!panning.active) {
        return;
      }
      panning.active = false;
      chart.classList.remove("is-panning");
    });
  }

  function initCurrentView() {
    document
      .querySelectorAll("[data-scxml-architect-shell]")
      .forEach(function (shell) {
        bindToolbar(shell);
      });
  }

  window.hyperdocScxmlArchitect = {
    initCurrentView: initCurrentView
  };
}());
