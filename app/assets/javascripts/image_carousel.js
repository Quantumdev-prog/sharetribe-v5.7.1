window.ST = window.ST || {};

ST.imageCarousel = function(images) {
  // Elements
  var tmpl = _.template($("#image-frame-template").html());
  var leftLink = $("#listing-image-navi-left");
  var rightLink = $("#listing-image-navi-right");
  var container = $("#listing-image-frame");
  var thumbnailContainer = $("#listing-image-thumbnails");
  var thumbnailOverflow = $("#listing-image-thumbnails-mask");

  // Initialize thumbnail elements
  var elements = _.map(images, function(image) {
    return $(tmpl({url: image.images.big, aspectRatioClass: image.aspectRatio }));
  });

  _.each(elements, function(el) {
    el.hide();
    container.append(el);
  });

  // Options
  var initialIdx = 0;
  var swipeDelay = 400;

  elements[initialIdx].show();

  var prevId = _.partial(ST.utils.prevIndex, elements.length);
  var nextId = _.partial(ST.utils.nextIndex, elements.length);

  function swipe(direction, newElement, oldElement) {
    var newStartDir = direction == "right" ? -1 : 1;
    var oldMoveDir = direction == "right" ? 1 : -1;

    newElement.transition({ x: newStartDir * newElement.width() }, 0);
    newElement.show();

    var oldDone = oldElement.transition({ x: oldMoveDir * oldElement.width() }, swipeDelay).promise();
    var newDone = newElement.transition({ x: 0 }, swipeDelay).promise();

    var bothDone = $.when(newDone, oldDone)
    bothDone.done(function() {
      oldElement.hide();
    });

    return bothDone;
  }

  // function show(idx) {
  function show(oldIdx, newIdx) {
    var goingRight = newIdx > oldIdx;
    var goingLeft = newIdx < oldIdx;

    var oldElement = elements[oldIdx];
    var newElement = elements[newIdx];

    // Notice, if going right, the swipe effect goes to from left
    if(goingRight) {
      swipe("left", newElement, oldElement);
    }
    if(goingLeft) {
      swipe("right", newElement, oldElement);
    }
  }

  // Prev/Next events
  var prev = leftLink.asEventStream("click").doAction(".preventDefault").debounceImmediate(swipeDelay);
  var next = rightLink.asEventStream("click").doAction(".preventDefault").debounceImmediate(swipeDelay);

  var prevIdxStream = prev.map(function() { return {value: null, fn: prevId} });
  var nextIdxStream = next.map(function() { return {value: null, fn: nextId} });

  var idxStreamBus = new Bacon.Bus();
  idxStreamBus.plug(prevIdxStream);
  idxStreamBus.plug(nextIdxStream);

  var idxStream = idxStreamBus.scan(initialIdx, function(a, b) {
    if (b.value) {
      return b.value;
    } else {
      return b.fn(a);
    }
  }).slidingWindow(2, 2);

  idxStream.onValues(show);

  return {
    prev: prev,
    next: next,
    show: function(showStream) {
      idxStreamBus.plug(showStream.map(function(idx) { return {value: idx}; }));
    }
  }
}