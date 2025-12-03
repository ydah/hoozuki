# Change log

## Unreleased

## 1.0.0 (2025-12-03)

### Breaking Changes

- Rename `NFA.new_from_node` to `NFA.from_node`. ([@ydah])

### Bug Fixes

- Fix choice node to support 3 or more alternatives (e.g., `a|b|c`). ([@ydah])
- Fix VM compiler to correctly handle multiple choice alternatives. ([@ydah])

## 0.2.0 (2025-08-25)

- Support VM engine for regex matching. ([@ydah])

## 0.1.0 (2025-08-23)

- Initial release

<!-- Contributors -->

[@ydah]: https://github.com/ydah
