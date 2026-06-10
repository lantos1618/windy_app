# Window Manipulation Logic Refinement

## Objective
Improve coordinate system conversions and safeAreaInsets handling.

## Status: ✅ COMPLETED - AUDIT PHASE

## Current Status
- [x] Investigate current coordinate system conversions
- [x] Review safeAreaInsets handling
- [x] Identify "magic numbers" and workarounds:
  - [x] errorX/errorY values
  - [x] max_check values
- [x] Research better approaches
- [ ] Implement more robust solutions
- [ ] Test on different screen configurations
- [x] Document the improvements

## Areas Focused On
- ✅ Coordinate system conversions (AppKit ↔ CoreGraphics)
- ✅ Safe area insets handling (commented out, needs re-evaluation)
- ✅ Multi-monitor support (raycasting algorithm)
- ✅ Different macOS versions compatibility

## Files Modified
- ✅ `utils.swift` - Added comprehensive comments for coordinate conversions
- ✅ `gridManager.swift` - Documented magic numbers and workarounds
- ✅ `snapWindow.swift` - Explained snap logic and coordinate usage
- ✅ `windyWindow.swift` - Documented Accessibility framework usage

## Magic Numbers & Workarounds Identified
- ✅ **errorX/errorY**: 30% error correction factors for coordinate system conversion issues
- ✅ **max_check**: 10,000 pixel limit for screen adjacency detection
- ✅ **Raycast step size**: 100 pixel increments for finding next screen
- ✅ **ESC key code**: 53 (hardcoded key code)
- ✅ **Gutter size**: 100px from screen edges for snap detection
- ✅ **Fixed grid**: 2x2 grid for window snapping

## Research Areas Completed
- ✅ Core Graphics coordinate systems (AppKit vs CoreGraphics origins)
- ✅ Window Server APIs (Accessibility framework usage)
- ✅ Safe area handling best practices (commented out, needs investigation)
- ✅ Multi-monitor coordinate systems (raycasting approach)

## Next Action
- [ ] **Implement improvements** based on audit findings:
  - [ ] Replace raycasting with proper screen adjacency detection
  - [ ] Investigate and fix coordinate system conversion issues (eliminate errorX/errorY)
  - [ ] Re-evaluate safeAreaInsets usage
  - [ ] Replace magic numbers with named constants

## Notes
- ✅ Current workarounds documented and understood
- ✅ Coordinate system conversions clearly explained
- ✅ All magic numbers identified and documented
- **Ready for implementation phase** 