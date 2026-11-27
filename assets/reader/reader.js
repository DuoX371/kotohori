// Kotohori book page script. Injected into each page by BookView.
//
// Pages mode: the page is one chapter, paginated with CSS columns; swipes and
// taps turn pages. Scroll mode: the page holds the whole book (BookView feeds
// every chapter in with kh.add, each becoming a <section>), scrolled freely.
// Taps and the reading position go to Flutter over the `Kotohori` channel.
//
// Character offsets count a chapter's visible text exactly like Dart's
// visibleText(): text nodes under its <body>, skipping rt, rp, script and
// style. In scroll mode each section holds its chapter's body, so offsets
// are counted within the section.
(function () {
  if (window.kh) return;

  var HIDDEN = { RT: 1, RP: 1, SCRIPT: 1, STYLE: 1 };
  var BLOCKS = 'p,h1,h2,h3,h4,h5,h6,li,blockquote,dd,dt,td,th,figcaption';
  var XLINK = 'http://www.w3.org/1999/xlink';
  // Letters and digits of any script (kanji, kana, ー, Latin, numbers).
  var WORDY = /[\p{L}\p{N}ー々〆ヶ]/u;
  // anchor: the offset the reader is "at" in chapter [ch] (scroll mode; in
  // pages mode the page is the chapter). Only page turns, scrolling and jumps
  // move it; re-layouts (settings, rotation) land on it again, so the place
  // never drifts.
  var state = { vertical: true, scroll: false, margin: 24, page: 0, pages: 1, ready: false, anchor: 0, ch: 0 };
  // Scroll mode: the chapters by spine index: { el: <section>, nodes: its
  // visible text nodes, len: its text length }.
  var sections = [];
  var seenStyles = {};

  function post(o) {
    try { Kotohori.postMessage(JSON.stringify(o)); } catch (e) {}
  }

  // Limits [sheet]'s rules to the element matching [scope]: html/body/:root
  // become [scope], everything else goes inside it; @page goes.
  // shortcut: splits selector lists on every comma, so :is(a, b) breaks; fine
  // for EPUB chapter styles, upgrade to @scope if one ever needs it.
  function scopeRules(sheet, scope) {
    var rules = sheet.cssRules;
    for (var i = rules.length - 1; i >= 0; i--) {
      var r = rules[i];
      if (r.type === 6) sheet.deleteRule(i); // @page
      else if (r.cssRules && r.type !== 1) scopeRules(r, scope); // @media, @supports
      else if (r.type === 1) r.selectorText = scopeSelector(r.selectorText, scope);
    }
  }

  function scopeSelector(list, scope) {
    return list.split(',').map(function (s) {
      s = s.trim().replace(/^(html|:root)(?![\w-])[^\s>+~]*\s*>?\s*/i, '');
      if (!s) return scope;
      if (/^body(?![\w-])/i.test(s)) return s.replace(/^body/i, scope);
      return scope + ' ' + s;
    }).join(', ');
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

  function sectionOf(node) {
    var el = node.nodeType === 1 ? node : node.parentNode;
    return el && el.closest ? el.closest('section.kh-ch') : null;
  }

  // What offsets and paragraphs are counted in: the chapter's section in
  // scroll mode, the page in pages mode.
  function rootOf(node) {
    return (state.scroll && sectionOf(node)) || document.body;
  }

  function blockOf(node) {
    var el = node.nodeType === 1 ? node : node.parentNode;
    return (el.closest && (el.closest(BLOCKS) || el.closest('div'))) || rootOf(node);
  }

  function blocks(root) {
    return Array.prototype.slice.call(root.querySelectorAll(BLOCKS + ',div'))
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

  // (node, index) for character [offset] of the text [nodes].
  function locate(offset, nodes) {
    var sum = 0;
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

  // Scroll mode: how far along the book the screen is, and how far it can go.
  // Vertical text runs right to left, so its scrollLeft goes negative.
  function along() {
    var b = document.body;
    return state.vertical ? -b.scrollLeft : b.scrollTop;
  }
  function room() {
    var b = document.body;
    return state.vertical ? b.scrollWidth - b.clientWidth : b.scrollHeight - b.clientHeight;
  }
  function scrollAlong(by, smooth) {
    document.body.scrollBy({
      left: state.vertical ? -by : 0,
      top: state.vertical ? 0 : by,
      behavior: smooth ? 'smooth' : 'instant',
    });
  }
  function atEnd() { return along() >= room() - 2; }
  function atStart() { return along() <= 2; }
  // One screen of text, less the margins, so no line is skipped.
  function screen() {
    return (state.vertical ? viewW() : viewH()) - 2 * state.margin;
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

  // Whether a character is on the current page (or screen) or after it. In
  // scroll mode only past the margin: a jump puts the place's line at the
  // margin, and the line before it, peeking out in the margin, must not
  // become the place (each reopen would land a line earlier).
  function reached(rect) {
    if (!state.scroll) return pageOfRect(rect) >= state.page;
    return state.vertical ? rect.left + rect.width / 2 < viewW() - state.margin
                          : rect.top + rect.height / 2 > state.margin;
  }

  // Offset in the text [nodes] of the first character whose box passes
  // [test], which must be false and then true in reading order; the text's
  // length if none does.
  function firstWhere(test, nodes) {
    var sum = 0;
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i], len = n.data.length;
      var last = len ? charRect(n, len - 1) : null;
      if (last && test(last)) {
        // First such character of this node: binary search.
        var lo = 0, hi = len - 1;
        while (lo < hi) {
          var mid = (lo + hi) >> 1, r = charRect(n, mid);
          if (r && test(r)) hi = mid; else lo = mid + 1;
        }
        return sum + lo;
      }
      sum += len;
    }
    return sum;
  }

  // Scroll mode: the first character in the book passing [test] (as in
  // firstWhere), as { ch, offset }; null if none.
  function firstInBook(test) {
    for (var i = 0; i < sections.length; i++) {
      var s = sections[i];
      if (!s || !s.len) continue;
      // A chapter whose last character fails has no character that passes.
      var end = locate(s.len - 1, s.nodes), er = end && charRect(end.node, end.index);
      if (er && !test(er)) continue;
      var o = firstWhere(test, s.nodes);
      if (o < s.len) return { ch: i, offset: o };
    }
    return null;
  }

  // Scroll mode: the character before [at] ({ ch, offset }), maybe in an
  // earlier chapter; null at the start of the book.
  function before(at) {
    if (at.offset > 0) return { ch: at.ch, offset: at.offset - 1 };
    for (var i = at.ch - 1; i >= 0; i--) {
      if (sections[i] && sections[i].len) return { ch: i, offset: sections[i].len - 1 };
    }
    return null;
  }

  // The box of character [at] ({ ch, offset }); for one without a box
  // (collapsed spaces, line breaks), the nearest with one in direction [dir]
  // (1 or -1; 1 by default).
  function rectAt(at, dir) {
    var s = at && sections[at.ch];
    if (!s) return null;
    for (var o = at.offset, n = 0; o >= 0 && o < s.len && n < 200; o += dir || 1, n++) {
      var l = locate(o, s.nodes), r = l && charRect(l.node, l.index);
      if (r) return r;
    }
    return null;
  }

  // Scroll mode: a chapter without text (a picture page) on screen before
  // the first character: that is the place (offset 0), so reopening shows
  // the picture instead of skipping it.
  function pictureBefore(at) {
    var w = viewW(), h = viewH(), found = null;
    for (var i = at.ch - 1; i >= 0 && sections[i] && sections[i].blank; i--) {
      var r = sections[i].el.getBoundingClientRect();
      var seen = state.vertical ? r.left < w && r.right > 0 : r.top < h && r.bottom > 0;
      if (!seen) break;
      found = { ch: i, offset: 0 };
    }
    return found || at;
  }

  // Pages mode: offset of the first character on the current page.
  function currentOffset() { return firstWhere(reached, textNodes(document.body)); }

  // [anchor]: keep this offset as the place (re-layout); otherwise the place
  // becomes the first character of the page (a page turn).
  function show(page, anchor) {
    kh.clearHighlight();
    state.page = Math.max(0, Math.min(state.pages - 1, page));
    setScroll(state.page * pageSize());
    state.anchor = anchor === undefined ? currentOffset() : anchor;
    post({ t: 'pos', offset: state.anchor, page: state.page, pages: state.pages });
  }

  // Scroll mode: report where the screen is: [at] ({ ch, offset }) to keep a
  // place (a jump, a re-layout), otherwise the first character on screen.
  // Pages are counted within the chapter, as in pages mode.
  function scrolled(at) {
    if (!at) {
      at = firstInBook(reached);
      // At the chapter's first visible character (it may start with line
      // breaks): a picture page before it may be the place.
      var top = at && firstWhere(function () { return true; }, sections[at.ch].nodes);
      if (at && at.offset <= top) at = pictureBefore(at);
    }
    if (!at) {
      var last = sections.length - 1;
      while (last > 0 && !(sections[last] && sections[last].len)) last--;
      at = { ch: Math.max(0, last), offset: sections[last] ? sections[last].len : 0 };
    }
    state.ch = at.ch;
    state.anchor = at.offset;
    var s = sections[at.ch], r = s && s.el.getBoundingClientRect();
    if (r) {
      var size = state.vertical ? r.width : r.height;
      var into = state.vertical ? r.right - viewW() : -r.top;
      state.pages = Math.max(1, Math.ceil(size / screen()));
      state.page = Math.max(0, Math.min(state.pages - 1, Math.round(into / screen())));
    }
    post({ t: 'pos', ch: at.ch, offset: at.offset, page: state.page, pages: state.pages });
  }

  // Scroll mode: bring [rect] to the start of the screen.
  function scrollTo(rect) {
    scrollAlong(state.vertical ? viewW() - state.margin - rect.right
                               : rect.top - state.margin, false);
  }

  // Scroll mode, a "page turn": the first line that doesn't fully fit moves to
  // the start of the screen (back: the screen before, lined up the same way),
  // so lines are never skipped or cut. At most about a screen, so a picture
  // in between isn't jumped over.
  function step(forward) {
    var v = state.vertical, w = viewW(), h = viewH(), m = state.margin, by;
    if (forward) {
      var r = rectAt(firstInBook(function (x) { return v ? x.left < 0 : x.bottom > h; }));
      by = r ? (v ? w - m - r.right : r.top - m) : room() - along();
      by = Math.min(by, (v ? w : h) - m);
    } else {
      var first = firstInBook(function (x) { return v ? x.right <= w : x.top >= 0; });
      var p = rectAt(first && before(first), -1);
      by = p ? (v ? m - p.left : p.bottom - h + m) : -along();
      by = Math.max(by, m - (v ? w : h));
      // Then line that screen up like a forward turn: its first whole line at
      // the start (where each line would be after moving [by]).
      var s = rectAt(firstInBook(function (x) {
        return v ? x.right + by <= w - m + 1 : x.top - by >= m - 1;
      }));
      if (s) by = v ? w - m - s.right : s.top - m;
    }
    if (Math.abs(by) < 1) by = forward ? screen() : -screen();
    kh.clearHighlight();
    scrollAlong(by, true);
  }

  // Shows chapter [ch] at [at]: an offset, 'end', or '#fragment'. In pages
  // mode the page is chapter [ch] already.
  function go(ch, at) {
    kh.clearHighlight();
    if (!state.scroll) {
      if (at === 'end') return show(state.pages - 1);
      if (typeof at === 'string' && at.charAt(0) === '#') {
        var el = document.getElementById(at.substring(1));
        var r = el && el.getClientRects()[0];
        return show(r ? pageOfRect(r) : 0);
      }
      var l = locate(at || 0, textNodes(document.body)), c = l && charRect(l.node, l.index);
      return show(c ? pageOfRect(c) : 0, at || 0);
    }
    var s = sections[ch];
    if (!s) return;
    if (typeof at === 'string' && at.charAt(0) === '#') {
      var id = at.substring(1), target = null;
      Array.prototype.some.call(s.el.querySelectorAll('[id]'), function (e) {
        return e.id === id && (target = e);
      });
      var tr = (target || s.el).getClientRects()[0];
      if (tr) scrollTo(tr);
      return scrolled();
    }
    var offset = at === 'end' ? Math.max(0, s.len - 1) : (at || 0);
    var hit = (s.len && rectAt({ ch: ch, offset: offset }, at === 'end' ? -1 : 1)) ||
      s.el.getClientRects()[0];
    if (hit) scrollTo(hit);
    scrolled({ ch: ch, offset: offset });
  }

  function layout() {
    var s = document.getElementById('kh-layout');
    if (!s) {
      s = document.createElement('style');
      s.id = 'kh-layout';
      document.head.appendChild(s);
    }
    var w = viewW(), h = viewH(), m = state.margin;
    // Pages: one column per page, running down (vertical) or across
    // (horizontal). Scroll: no columns; the body scrolls along the text, with
    // a gap between chapters.
    var flow = !state.scroll
      ? 'overflow:hidden !important;column-fill:auto !important;column-gap:' + (2 * m) +
        'px !important;column-width:' + ((state.vertical ? h : w) - 2 * m) + 'px !important;'
      : (state.vertical ? 'overflow-x:auto !important;overflow-y:hidden !important;'
                        : 'overflow-y:auto !important;overflow-x:hidden !important;') +
        'columns:auto !important;';
    s.textContent =
      'html{overflow:hidden !important;touch-action:' +
      (!state.scroll ? 'none' : state.vertical ? 'pan-x' : 'pan-y') + ' !important;' +
      'height:' + h + 'px !important;width:' + w + 'px !important;' +
      'margin:0 !important;padding:0 !important;}' +
      'body{box-sizing:border-box !important;' + flow +
      'width:' + w + 'px !important;height:' + h + 'px !important;max-width:none !important;}' +
      'section.kh-ch{display:block;margin:0;padding:0;}' +
      'section.kh-ch+section.kh-ch{margin-block-start:' + (2 * m) + 'px;}' +
      'img,svg{break-inside:avoid;}' +
      'img,image{-webkit-user-drag:none;-webkit-touch-callout:none;user-select:none;}' +
      (state.vertical ? '' : '.kh-after-heading{display:none !important;}') +
      'img{max-width:' + Math.floor((w - 2 * m) * 0.94) + 'px !important;' +
      'max-height:' + Math.floor((h - 2 * m) * 0.94) + 'px !important;' +
      'object-fit:contain !important;vertical-align:top;}' +
      'svg:has(image){height:' + Math.floor((h - 2 * m) * 0.94) + 'px !important;' +
      'width:auto !important;max-width:' + Math.floor((w - 2 * m) * 0.94) +
      'px !important;}';
    if (!state.scroll) countPages();
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

  // Scroll mode: links and pictures in a chapter point relative to its own
  // file; inside the book page they must point there in full.
  function absolute(el, url) {
    ['src', 'href', 'poster'].forEach(function (a) {
      var v = el.getAttribute(a);
      if (v !== null) {
        try { el.setAttribute(a, new URL(v, url).href); } catch (e) {}
      }
    });
    var x = el.getAttributeNS(XLINK, 'href');
    if (x !== null) {
      try { el.setAttributeNS(XLINK, 'xlink:href', new URL(x, url).href); } catch (e) {}
    }
  }

  window.kh = {
    // Scroll mode: adds chapter [ch] (spine index; called in order) from its
    // file's [html], at [url], parsed as [mime] like when it opens alone.
    add: function (ch, url, mime, html) {
      var doc = null;
      try {
        doc = new DOMParser().parseFromString(html, mime);
        if (doc.getElementsByTagName('parsererror').length) doc = null;
      } catch (e) { doc = null; }
      if (!doc) doc = new DOMParser().parseFromString(html, 'text/html');
      // The chapter's stylesheets, each once, before the reader's own.
      Array.prototype.forEach.call(doc.querySelectorAll('link, style'), function (el) {
        if (el.id === 'kh-hide') return;
        var tag = el.tagName.toLowerCase(), add;
        if (tag === 'link') {
          if (!/(^|\s)stylesheet(\s|$)/i.test(el.getAttribute('rel') || '')) return;
          var href;
          try { href = new URL(el.getAttribute('href'), url).href; } catch (e) { return; }
          if (seenStyles[href]) return;
          seenStyles[href] = 1;
          add = document.createElement('link');
          add.rel = 'stylesheet';
          add.href = href;
        } else {
          add = document.createElement('style');
          add.textContent = el.textContent;
        }
        var mine = document.getElementById('kh-style');
        document.head.insertBefore(add, mine || null);
        if (tag === 'style' && add.sheet) {
          try { scopeRules(add.sheet, 'section.kh-ch[data-ch="' + ch + '"]'); } catch (e) {}
        }
      });
      // The book's class on <html> (e.g. "vrtl") and the chapter's on <body>.
      var html_ = doc.documentElement;
      if (html_ && html_.classList) {
        html_.classList.forEach(function (c) { document.documentElement.classList.add(c); });
      }
      var sec = document.createElement('section');
      sec.className = 'kh-ch';
      sec.setAttribute('data-ch', ch);
      var body = doc.body || doc.getElementsByTagName('body')[0];
      if (body) {
        if (body.classList) body.classList.forEach(function (c) { sec.classList.add(c); });
        while (body.firstChild) sec.appendChild(document.adoptNode(body.firstChild));
      }
      absolute(sec, url);
      Array.prototype.forEach.call(sec.querySelectorAll('*'), function (el) { absolute(el, url); });
      document.body.appendChild(sec);
      var nodes = textNodes(sec), len = 0, text = '';
      nodes.forEach(function (n) { len += n.data.length; text += n.data; });
      // blank: no text to read (a picture page), maybe some line breaks.
      sections[ch] = { el: sec, nodes: nodes, len: len, blank: !text.trim() };
    },
    // css: the reader's style; at: an offset, 'end' or '#fragment' (pages
    // mode, in this chapter), or { ch, at } (scroll mode, in the book).
    init: function (css, vertical, margin, at, scroll) {
      state.vertical = vertical;
      state.margin = margin;
      state.scroll = !!scroll;
      // The other direction's scroll position means nothing here.
      document.body.scrollTop = 0;
      document.body.scrollLeft = 0;
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
        if (!state.scroll) countPages();
        state.ready = true;
        if (state.scroll) go(at.ch, at.at);
        else go(0, at);
      });
    },
    go: function (ch, at) { go(ch, at); },
    next: function () {
      if (state.scroll) {
        if (!atEnd()) step(true);
      } else if (state.page + 1 < state.pages) show(state.page + 1);
      else post({ t: 'edge', dir: 'next' });
    },
    prev: function () {
      if (state.scroll) {
        if (!atStart()) step(false);
      } else if (state.page > 0) show(state.page - 1);
      else post({ t: 'edge', dir: 'prev' });
    },
    // Highlights in the paragraph [para] of the chapter last tapped.
    highlight: function (para, start, length) {
      kh.clearHighlight();
      marked = [para, start, length];
      var root = state.scroll ? (sections[tapped] && sections[tapped].el) : document.body;
      var b = root && blocks(root)[para];
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
      marked = null;
      Array.prototype.forEach.call(document.querySelectorAll('.kh-mark'),
        function (m) { m.remove(); });
    },
  };

  // Scroll mode: the highlight is drawn in screen coordinates, so it is
  // redrawn as the text moves. The position is reported every so often while
  // scrolling (the page number keeps up) and once more when it rests.
  var marked = null, rest = null, busy = false, tapped = 0;
  document.body.addEventListener('scroll', function () {
    if (!state.ready || !state.scroll) return;
    if (marked) kh.highlight(marked[0], marked[1], marked[2]);
    clearTimeout(rest);
    rest = setTimeout(function () { scrolled(); }, 150);
    if (busy) return;
    busy = true;
    setTimeout(function () { busy = false; scrolled(); }, 100);
  }, { passive: true });

  window.addEventListener('resize', function () {
    if (!state.ready) return;
    layout();
    go(state.ch, state.anchor);
  });

  // The file of the picture [el] is in (<image> is one inside an <svg>), or null.
  function pictureAt(el) {
    var pic = el && el.closest && el.closest('img, image');
    if (!pic) return null;
    return pic.tagName.toLowerCase() === 'img'
      ? pic.currentSrc || pic.src || null
      : new URL(pic.getAttribute('href') || pic.getAttribute('xlink:href') || '', document.baseURI).href;
  }

  // Holding a picture still: Flutter starts a drag to other apps. Moving or
  // lifting the finger first is a scroll, swipe or tap instead.
  var hold = null;
  function dropHold() { clearTimeout(hold); hold = null; }
  document.addEventListener('contextmenu', function (e) {
    if (pictureAt(e.target)) e.preventDefault();
  });
  document.addEventListener('touchmove', function (e) {
    if (!hold || !touch) return;
    var t = e.touches[0];
    if (Math.abs(t.clientX - touch.x) > 10 || Math.abs(t.clientY - touch.y) > 10) dropHold();
  }, { passive: true });

  // Pages mode: swipe = turn the page. Vertical books: finger left → right
  // is next. Scroll mode: the finger just scrolls.
  var touch = null, swiped = false;
  document.addEventListener('touchstart', function (e) {
    var t = e.touches[0];
    touch = { x: t.clientX, y: t.clientY };
    swiped = false;
    dropHold();
    var src = e.touches.length === 1 && pictureAt(e.target);
    if (src) {
      hold = setTimeout(function () {
        hold = null;
        swiped = true; // the release isn't a tap
        post({ t: 'imageHold', src: src });
      }, 450);
    }
  }, { passive: true });
  document.addEventListener('touchend', function (e) {
    dropHold();
    if (!touch) return;
    var t = e.changedTouches[0], dx = t.clientX - touch.x, dy = t.clientY - touch.y;
    touch = null;
    if (state.scroll) return;
    if (Math.abs(dx) > 50 && Math.abs(dx) > Math.abs(dy)) {
      swiped = true;
      if ((dx > 0) === state.vertical) kh.next(); else kh.prev();
    }
  }, { passive: true });

  document.addEventListener('click', function (e) {
    if (swiped) { swiped = false; return; }
    if (e.target.closest && e.target.closest('a[href]')) return; // a link: Flutter follows it
    var src = pictureAt(e.target);
    if (src) return post({ t: 'image', src: src });
    var caret = document.caretRangeFromPoint(e.clientX, e.clientY);
    var node = caret && caret.startContainer;
    var blank = { t: 'blank', x: e.clientX / viewW(), w: viewW(), y: e.clientY / viewH(), h: viewH() };
    if (node && node.nodeType === 3 && hidden(node)) return post({ t: 'blank' });
    if (!node || node.nodeType !== 3) return post(blank);
    // The caret is the nearest gap; take the character actually under the finger.
    var index = -1;
    [caret.startOffset, caret.startOffset - 1].forEach(function (i) {
      if (index >= 0 || i < 0 || i >= node.data.length) return;
      var r = charRect(node, i);
      if (r && e.clientX >= r.left - 2 && e.clientX <= r.right + 2 &&
          e.clientY >= r.top - 2 && e.clientY <= r.bottom + 2) index = i;
    });
    // Punctuation, brackets and spaces aren't words: treat them as blank space.
    if (index < 0 || !WORDY.test(node.data[index])) return post(blank);
    var root = rootOf(node);
    if (state.scroll) {
      if (root === document.body) return post(blank); // not in a chapter
      tapped = +root.getAttribute('data-ch');
    }
    var block = blockOf(node), all = blocks(root), para = all.indexOf(block);
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
