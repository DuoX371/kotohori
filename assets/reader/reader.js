// Kotohori book page script. Injected into each chapter page by BookView.
// Paginates with CSS columns, turns pages on swipe, and reports taps and the
// reading position to Flutter over the `Kotohori` JavaScript channel.
//
// Character offsets count the chapter's visible text exactly like Dart's
// visibleText(): text nodes under <body>, skipping rt, rp, script and style.
(function () {
  if (window.kh) return;

  var HIDDEN = { RT: 1, RP: 1, SCRIPT: 1, STYLE: 1 };
  var BLOCKS = 'p,h1,h2,h3,h4,h5,h6,li,blockquote,dd,dt,td,th,figcaption';
  // Letters and digits of any script (kanji, kana, ー, Latin, numbers).
  var WORDY = /[\p{L}\p{N}ー々〆ヶ]/u;
  // anchor: the chapter offset the reader is "at". Only page turns and jumps
  // move it; re-layouts (settings, rotation) land on it again, so the place
  // never drifts.
  var state = { vertical: true, margin: 24, page: 0, pages: 1, ready: false, anchor: 0 };

  function post(o) {
    try { Kotohori.postMessage(JSON.stringify(o)); } catch (e) {}
  }

  function hidden(node) {
    for (var n = node.parentNode; n && n !== document.body; n = n.parentNode) {
      if (n.nodeType === 1 && HIDDEN[n.nodeName.toUpperCase()]) return true;
    }
    return false;
  }

  // Visible text nodes under [root], in order.
  function textNodes(root) {
    var out = [];
    var w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null);
    for (var n = w.nextNode(); n; n = w.nextNode()) {
      if (!hidden(n)) out.push(n);
    }
    return out;
  }

  function blockOf(node) {
    var el = node.nodeType === 1 ? node : node.parentNode;
    return (el.closest && (el.closest(BLOCKS) || el.closest('div'))) || document.body;
  }

  function blocks() {
    return Array.prototype.slice.call(document.body.querySelectorAll(BLOCKS + ',div'))
      .filter(function (b) { return !b.querySelector(BLOCKS + ',div'); });
  }

  function visible(el) {
    return textNodes(el).map(function (n) { return n.data; }).join('');
  }

  // Offset of (node, index) within the visible text of [root].
  function offsetIn(root, node, index) {
    var nodes = textNodes(root), sum = 0;
    for (var i = 0; i < nodes.length; i++) {
      if (nodes[i] === node) return sum + index;
      sum += nodes[i].data.length;
    }
    return sum;
  }

  // (node, index) for chapter character [offset].
  function locate(offset) {
    var nodes = textNodes(document.body), sum = 0;
    for (var i = 0; i < nodes.length; i++) {
      var len = nodes[i].data.length;
      if (offset < sum + len) return { node: nodes[i], index: offset - sum };
      sum += len;
    }
    var last = nodes[nodes.length - 1];
    return last ? { node: last, index: Math.max(0, last.data.length - 1) } : null;
  }

  // The screen's size. Not innerWidth/innerHeight: Android WebViews grow the
  // layout viewport to fit wide content (vertical books overflow sideways).
  function viewW() { return document.documentElement.clientWidth; }
  function viewH() { return document.documentElement.clientHeight; }

  function pageSize() {
    return state.vertical ? viewH() : viewW();
  }

  function scrollPos() {
    return state.vertical ? document.body.scrollTop : document.body.scrollLeft;
  }

  function setScroll(v) {
    if (state.vertical) document.body.scrollTop = v;
    else document.body.scrollLeft = v;
  }

  function countPages() {
    var size = state.vertical ? document.body.scrollHeight : document.body.scrollWidth;
    state.pages = Math.max(1, Math.round(size / pageSize()));
  }

  function charRect(node, index) {
    var r = document.createRange();
    var end = Math.min(index + 1, node.data.length);
    r.setStart(node, Math.min(index, end));
    r.setEnd(node, end);
    var rects = r.getClientRects();
    return rects.length ? rects[0] : null;
  }

  // Page holding a rect (client coordinates).
  function pageOfRect(rect) {
    var pos = state.vertical ? rect.top + rect.height / 2 : rect.left + rect.width / 2;
    return Math.max(0, Math.min(state.pages - 1, Math.floor((pos + scrollPos()) / pageSize())));
  }

  // Chapter offset of the first character on the current page.
  function currentOffset() {
    var nodes = textNodes(document.body), sum = 0;
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i], len = n.data.length;
      var last = len ? charRect(n, len - 1) : null;
      if (last && pageOfRect(last) >= state.page) {
        // First character of this node on the page: binary search.
        var lo = 0, hi = len - 1;
        while (lo < hi) {
          var mid = (lo + hi) >> 1, r = charRect(n, mid);
          if (r && pageOfRect(r) >= state.page) hi = mid; else lo = mid + 1;
        }
        return sum + lo;
      }
      sum += len;
    }
    return sum;
  }

  // [anchor]: keep this offset as the place (re-layout); otherwise the place
  // becomes the first character of the page (a page turn).
  function show(page, anchor) {
    kh.clearHighlight();
    state.page = Math.max(0, Math.min(state.pages - 1, page));
    setScroll(state.page * pageSize());
    state.anchor = anchor === undefined ? currentOffset() : anchor;
    post({ t: 'pos', offset: state.anchor, page: state.page, pages: state.pages });
  }

  function goToOffset(offset) {
    var at = locate(offset), r = at && charRect(at.node, at.index);
    show(r ? pageOfRect(r) : 0, offset);
  }

  function layout() {
    var s = document.getElementById('kh-layout');
    if (!s) {
      s = document.createElement('style');
      s.id = 'kh-layout';
      document.head.appendChild(s);
    }
    var w = viewW(), h = viewH(), m = state.margin;
    // One column per page: pages run down (vertical) or across (horizontal).
    s.textContent =
      'html{overflow:hidden !important;touch-action:none !important;' +
      'height:' + h + 'px !important;width:' + w + 'px !important;}' +
      'body{box-sizing:border-box !important;overflow:hidden !important;' +
      'width:' + w + 'px !important;height:' + h + 'px !important;max-width:none !important;' +
      'column-fill:auto !important;column-gap:' + (2 * m) + 'px !important;' +
      'column-width:' + ((state.vertical ? h : w) - 2 * m) + 'px !important;}' +
      'img,svg{break-inside:avoid;}' +
      (state.vertical ? '' : '.kh-after-heading{display:none !important;}') +
      'img{max-width:' + Math.floor((w - 2 * m) * 0.94) + 'px !important;' +
      'max-height:' + Math.floor((h - 2 * m) * 0.94) + 'px !important;' +
      'object-fit:contain !important;vertical-align:top;}' +
      'svg:has(image){height:' + Math.floor((h - 2 * m) * 0.94) + 'px !important;' +
      'width:auto !important;max-width:' + Math.floor((w - 2 * m) * 0.94) +
      'px !important;}';
    countPages();
  }

  function markBlankAfterHeadings() {
    document.querySelectorAll('h1,h2,h3,h4,h5,h6').forEach(function (h) {
      for (var n = h.nextElementSibling; n && n.tagName.toUpperCase() === 'P' &&
          !n.textContent.trim() && !n.querySelector('img,svg,image');
          n = n.nextElementSibling) {
        n.classList.add('kh-after-heading');
      }
    });
  }

  function settle(then) {
    var waits = [];
    if (document.fonts && document.fonts.ready) waits.push(document.fonts.ready);
    Array.prototype.forEach.call(document.images, function (img) {
      if (!img.complete) {
        waits.push(new Promise(function (ok) { img.onload = img.onerror = ok; }));
      }
    });
    Promise.all(waits).then(function () { requestAnimationFrame(then); });
  }

  window.kh = {
    // css: the reader's style; at: chapter offset, 'end', or '#fragment'.
    init: function (css, vertical, margin, at) {
      state.vertical = vertical;
      state.margin = margin;
      var s = document.getElementById('kh-style');
      if (!s) {
        s = document.createElement('style');
        s.id = 'kh-style';
        document.head.appendChild(s);
      }
      s.textContent = css;
      markBlankAfterHeadings();
      layout();
      settle(function () {
        // Laid out the reader's way: the page may show now (see hidePage).
        var hide = document.getElementById('kh-hide');
        if (hide) hide.remove();
        countPages();
        state.ready = true;
        if (at === 'end') show(state.pages - 1);
        else if (typeof at === 'string' && at.charAt(0) === '#') {
          var el = document.getElementById(at.substring(1));
          var r = el && el.getClientRects()[0];
          show(r ? pageOfRect(r) : 0);
        } else goToOffset(at || 0);
      });
    },
    next: function () {
      if (state.page + 1 < state.pages) show(state.page + 1);
      else post({ t: 'edge', dir: 'next' });
    },
    prev: function () {
      if (state.page > 0) show(state.page - 1);
      else post({ t: 'edge', dir: 'prev' });
    },
    highlight: function (para, start, length) {
      kh.clearHighlight();
      var b = blocks()[para];
      if (!b) return;
      // Character boxes in the same line merge into one rounded box.
      var nodes = textNodes(b), sum = 0, end = start + length, boxes = [];
      for (var i = 0; i < nodes.length && sum < end; i++) {
        var n = nodes[i], len = n.data.length;
        var em = parseFloat(getComputedStyle(n.parentNode).fontSize) || 16;
        for (var j = Math.max(start, sum); j < Math.min(end, sum + len); j++) {
          var r = charRect(n, j - sum);
          if (!r) continue;
          var x = state.vertical ? r.left + r.width / 2 - em / 2 : r.left;
          var y = state.vertical ? r.top : r.top + r.height / 2 - em / 2;
          var w = state.vertical ? em : r.width, h = state.vertical ? r.height : em;
          var last = boxes[boxes.length - 1];
          if (last && (state.vertical ? Math.abs(last.x - x) < 2 : Math.abs(last.y - y) < 2)) {
            var x2 = Math.max(last.x + last.w, x + w), y2 = Math.max(last.y + last.h, y + h);
            last.x = Math.min(last.x, x);
            last.y = Math.min(last.y, y);
            last.w = x2 - last.x;
            last.h = y2 - last.y;
          } else boxes.push({ x: x, y: y, w: w, h: h });
        }
        sum += len;
      }
      boxes.forEach(function (o) {
        var box = document.createElement('div');
        box.className = 'kh-mark';
        box.style.cssText = 'position:fixed;z-index:-1;pointer-events:none;' +
          'border-radius:4px;background:rgba(226,184,92,.45);' +
          'left:' + o.x + 'px;top:' + o.y + 'px;width:' + o.w + 'px;height:' + o.h + 'px;';
        document.body.appendChild(box);
      });
    },
    clearHighlight: function () {
      Array.prototype.forEach.call(document.querySelectorAll('.kh-mark'),
        function (m) { m.remove(); });
    },
  };

  window.addEventListener('resize', function () {
    if (!state.ready) return;
    layout();
    goToOffset(state.anchor);
  });

  // Swipe = turn the page. Vertical books: finger left → right is next.
  var touch = null, swiped = false;
  document.addEventListener('touchstart', function (e) {
    var t = e.touches[0];
    touch = { x: t.clientX, y: t.clientY };
    swiped = false;
  }, { passive: true });
  document.addEventListener('touchend', function (e) {
    if (!touch) return;
    var t = e.changedTouches[0], dx = t.clientX - touch.x, dy = t.clientY - touch.y;
    touch = null;
    if (Math.abs(dx) > 50 && Math.abs(dx) > Math.abs(dy)) {
      swiped = true;
      if ((dx > 0) === state.vertical) kh.next(); else kh.prev();
    }
  }, { passive: true });

  // Tap = look up the character under the finger, or blank = toggle the menu.
  document.addEventListener('click', function (e) {
    if (swiped) { swiped = false; return; }
    if (e.target.closest && e.target.closest('a[href]')) return; // a link: Flutter follows it
    var caret = document.caretRangeFromPoint(e.clientX, e.clientY);
    var node = caret && caret.startContainer;
    if (node && node.nodeType === 3 && hidden(node)) return post({ t: 'blank' });
    if (!node || node.nodeType !== 3) return post({ t: 'blank', x: e.clientX / viewW(), w: viewW(), y: e.clientY / viewH(), h: viewH() });
    // The caret is the nearest gap; take the character actually under the finger.
    var index = -1;
    [caret.startOffset, caret.startOffset - 1].forEach(function (i) {
      if (index >= 0 || i < 0 || i >= node.data.length) return;
      var r = charRect(node, i);
      if (r && e.clientX >= r.left - 2 && e.clientX <= r.right + 2 &&
          e.clientY >= r.top - 2 && e.clientY <= r.bottom + 2) index = i;
    });
    // Punctuation, brackets and spaces aren't words: treat them as blank space.
    if (index < 0 || !WORDY.test(node.data[index])) return post({ t: 'blank', x: e.clientX / viewW(), w: viewW(), y: e.clientY / viewH(), h: viewH() });
    var block = blockOf(node), all = blocks(), para = all.indexOf(block);
    function around(from, step) {
      var out = [];
      for (var i = from; i >= 0 && i < all.length && out.length < 2; i += step) {
        var text = visible(all[i]);
        if (text.trim()) out.push(text);
      }
      return step < 0 ? out.reverse() : out;
    }
    post({
      t: 'tap',
      para: para,
      text: visible(block),
      offset: offsetIn(block, node, index),
      before: para < 0 ? [] : around(para - 1, -1),
      after: para < 0 ? [] : around(para + 1, 1),
      x: e.clientX / viewW(),
    });
  });
})();
