/**
 * Apply css styles on d3 selection. Allow allow few non-css visual properties
 * to be set.
 */
export function applyStyle (d3Selection, style) {
  for (let key in style || {}) {
    if (key === 'r') {
      d3Selection.attr(key, style[key])
    } else {
      d3Selection.style(key, style[key])
    }
  }
}
