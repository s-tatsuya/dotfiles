// mpls のプレビューで ```markmap のコードブロックをマインドマップとして描く。
// helix.nix の mpls のパッチで、d3 / markmap-lib / markmap-view の後ろ、mpls の ws.js の
// 後ろに連結される（ライブラリは window.d3 / window.markmap に載っている）。
//
// mpls はコードブロックを <pre><code class="language-markmap"> として出し、編集のたびに
// #content の中身を丸ごと差し替える。#content の子要素の入れ替わりを監視して描き直す。
(function () {
  "use strict";

  function renderMarkmaps() {
    const mm = window.markmap;
    if (!mm || !mm.Transformer || !mm.Markmap) return;
    const blocks = document.querySelectorAll("#content code.language-markmap");
    if (blocks.length === 0) return;

    const transformer = new mm.Transformer();
    blocks.forEach((code) => {
      const target = code.closest("pre") || code;
      try {
        const { root } = transformer.transform(code.textContent || "");
        const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
        svg.classList.add("markmap");
        target.replaceWith(svg);
        // duration: 0 で描画アニメーションを省く（編集のたびに描き直すため）。
        mm.Markmap.create(svg, { duration: 0 }, root);
      } catch (error) {
        console.error("markmap failed:", error);
        const err = document.createElement("div");
        err.className = "markmap-error";
        err.textContent = "Markmap Error: " + (error && error.message ? error.message : String(error));
        target.replaceWith(err);
      }
    });
  }

  function start() {
    const content = document.getElementById("content");
    if (!content) return;
    new MutationObserver(renderMarkmaps).observe(content, { childList: true });
    renderMarkmaps();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start);
  } else {
    start();
  }
})();
