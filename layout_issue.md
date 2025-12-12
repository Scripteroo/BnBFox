# Layout Issue Analysis

## Problem
The booking bars and property labels are overlapping with date numbers and appearing in wrong positions across the calendar.

## Observations from Screenshot
1. Property labels (C-2, E-5) are appearing ON TOP of date numbers
2. Booking bars are not aligned properly within the week rows
3. Text labels are scattered randomly across the calendar
4. The layout structure seems to have broken completely

## Likely Causes
1. **GeometryReader issue**: The ContinuousBookingBar uses GeometryReader which might not be getting the correct parent width
2. **Property label overlay**: The property shortName text overlay (lines 366-373) is positioned incorrectly
3. **ZStack alignment**: The booking bars VStack might not be aligned correctly with the date grid

## Fix Strategy
1. Remove or reposition the property label text that's overlaying the bars
2. Ensure GeometryReader gets proper width from parent
3. Verify the booking bar positioning logic
4. Consider simplifying the overlay structure
