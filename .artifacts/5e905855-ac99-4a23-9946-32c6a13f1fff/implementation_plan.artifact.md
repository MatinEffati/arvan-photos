# Implement Floating Bottom Navigation Bar

This plan covers the implementation of a custom floating bottom navigation bar and a separate floating search button, as per the provided design.

## User Review Required

> [!IMPORTANT]
> - The new "Online Space" tab will be added as a placeholder for now.
> - The Search button will be separated from the main navigation bar but will still control the main content display.
> - The UI will use a beige/peach color scheme similar to the provided image.

## Proposed Changes

### [Component Name] Features/Photos/Presentation

#### [MODIFY] [main_navigation_screen.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/screens/main_navigation_screen.dart)
- Update `_screens` to include "Collections", "Create", "Online Space", and "Search".
- Replace `bottomNavigationBar` with a `Stack` based layout to overlay the floating bars.
- Implement the main floating navigation bar (Capsule shape).
- Implement the separate floating search button (Circle).
- Add logic to switch between screens based on the selected index.

#### [NEW] [floating_nav_bar.dart](file:///C:/Users/SE7EN-PC/StudioProjects/arvan_photos/lib/features/photos/presentation/widgets/floating_nav_bar.dart)
- Create a reusable widget for the main floating navigation bar.
- Create a reusable widget for the floating search button.

## Verification Plan

### Manual Verification
- Verify that clicking each tab in the floating bar correctly switches the screen.
- Verify that the search button correctly switches to the search screen.
- Verify the UI matches the provided image (colors, shapes, floating effect).
- Test on different screen sizes to ensure proper positioning.
