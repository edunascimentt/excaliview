import { exportToSvg, restore } from "@excalidraw/excalidraw";

// Renders the contents of a .excalidraw file into #root as an SVG.
// Called from Swift via callAsyncJavaScript.
window.renderExcalidraw = async (text, dark) => {
  const root = document.getElementById("root");
  try {
    const data = JSON.parse(text);
    const { elements, appState, files } = restore(data, null, null);
    const visible = elements.filter((el) => !el.isDeleted);
    document.documentElement.classList.toggle("dark", !!dark);

    if (visible.length === 0) {
      root.innerHTML = '<p class="msg">Empty drawing</p>';
      return { width: 400, height: 300 };
    }

    const svg = await exportToSvg({
      elements: visible,
      appState: {
        ...appState,
        exportBackground: true,
        exportWithDarkMode: !!dark,
        exportEmbedScene: false,
      },
      files,
      exportPadding: 24,
    });

    const width = parseFloat(svg.getAttribute("width")) || 800;
    const height = parseFloat(svg.getAttribute("height")) || 600;
    svg.setAttribute("viewBox", svg.getAttribute("viewBox") || `0 0 ${width} ${height}`);
    svg.removeAttribute("width");
    svg.removeAttribute("height");
    root.replaceChildren(svg);
    document.body.style.background =
      dark ? "#121212" : appState.viewBackgroundColor || "#ffffff";
    return { width, height };
  } catch (err) {
    root.innerHTML = "";
    const p = document.createElement("p");
    p.className = "msg";
    p.textContent = "Could not render drawing: " + (err && err.message ? err.message : err);
    root.appendChild(p);
    return { width: 400, height: 300, error: String(err) };
  }
};
