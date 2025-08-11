//= === === === === === === === === === === === === === === === === === === ===
// OpenSCAD setup:
//   - Edit > Preferences > Features> [x] manifold
//   - Design > [x] Automatic Reload and Preview 
//   - Window > [ ] Hide Customizer (so it visible in the right sidebar)
//   - In customizer: 
//     - [x] Automatic Preview
//     - (dropdown) Description Only
// VS Code setup:
//  - Add extension: leathong.openscad-language-support
//= === === === === === === === === === === === === === === === === === === ===

// General nomenclature, outside of any active rotations:
// * x - Left and right are the negative and positive x-axis, respectively.
// * y - Front and back are the negative and positive y-axis, respectively.
// * z - Bottom and Top are the positive and negative z-axis, respectively.
// * x - "Width" is the measurement between left and right, and is along the x-axis.
// * y - "Depth" is the measurement between front and back, and is along the y-axis.
// * z - "Height" is the measurement between bottom and top, and is along the z-axis.
//
// *Describe* objects as they are oriented in the final assembly, not as they are
//   oriented for printing (following the above nomenclature).
// *Render* objects as they are oriented for printing, not as they are oriented
//   in the final assembly (swapping the y and z values at render time). 
// heal, fan, heal


// Customizer

/*[Render]*/
render="all-selected"; // [all-selected: Render all selected slices, fan-slice: Fan slice, filter-box: Filter box, swoop: Swoop slice, dovetail: Dovetail clip]

// Include Fan Slice
include_fan_slice = true;
// Include Box Filter Slice
include_box_filter_slice = true;
// Include Fine Dust Filter Slice
include_fine_dust_filter_slice = true;
// Include Swoop Slice
include_swoop_slice = true;

/*[Fan Slice]*/
// Width (x) of the fan slice
fan_width = 119.6;
// Depth (y) of the fan slice
fan_depth = 25.7;
// Height (z) of the fan slice
fan_height = 119.6;
// Include wireing channel
include_wiring_channel = true;
// Fan slice has retaining wall
fan_has_retaining_wall = true;
// Fan slice has retaining lip
fan_has_retaining_lip = true;

/*[Box Filter Slice]*/
// Width (x) of the box filter slice
box_filter_width = 125.9;
// Depth (y) of the box filter slice
box_filter_depth = 39.5;
// Height (z) of the box filter slice
box_filter_height = 125.9;
// Box filter slice has retaining wall
box_filter_has_retaining_wall = true;
// Box filter slice has retaining lip
box_filter_has_retaining_lip = true;

/*[Swoop Slice]*/
// Depth (y) of the swoop slice, not including the swoop itself
swoop_depth = 80.5;
// Swoop angle, in degrees
swoop_angle = 98; // [0:180] The angle of the swoop, in degrees. This is the angle of the swoop from the front to the back, not the angle of the swoop from the top to the bottom.

/*[Outer Walls]*/
// Minimum wall thinckness
outer_wall_minimum = 3.5;
// Corner radius (r)
outer_wall_corner_radius = 5.2;

/*[Common Features]*/
// Retaining wall/lip depth (y)
retaining_depth = 1.6;
// Retaining hex "radius" (r)
retaining_hex_radius = 6.5;
// retaining hex edge width
retaining_hex_edge_width = 0.1; // [0.1:0.1:5]
// retaining lip inset
retaining_lip_inset = 1.5;
// Include feet
include_feet = true; // [true: Include the feet, false: Exclude the feet]
// Feet inside radius (r)
feet_inside_radius = 8.1;

/*[Dovetail]*/
// Include dovetail
include_dovetail = true;
// Dovetail width
dovetail_width = 20.0;
// Dovetail depth
dovetail_depth = 2.0;

/*[Hidden]*/
large_cutout_length = 200;
$fn = 128;
_sqrt2 = sqrt(2);
slop = 0.01; // Small offset to avoid z-fighting

//= === === === === === === === === === === === === === === === === === === ===
// Main

main();

module main() {
    if (render == "all-selected") {
        render_all_selected();
    } else if (render == "fan-slice") {
        fan_slice();
    } else if (render == "filter-box") {
        box_filter_slice();
    } else if (render == "swoop") {
        swoop_slice();
    } else if (render == "dovetail") {
        dovetail_clip();
    }
}

module render_all_selected() {
    interspace = 50; // Space between slices
    dimensions = loaf_dimensions();
    translate([0, 0, dimensions[2] / 2])
    rotate([90, 0, 90])
    {
        if (include_fan_slice)
            fan_slice();

        if (include_box_filter_slice)
            translate([0, 0, 0
                + (include_fan_slice ? interspace + fan_depth + (fan_has_retaining_wall ? retaining_depth : 0) : 0)])
            box_filter_slice();

        if (include_swoop_slice)
            translate([0, 0, 0
                + (include_fan_slice ? interspace + fan_depth + (fan_has_retaining_wall ? retaining_depth : 0) : 0)
                + (include_box_filter_slice ? interspace + box_filter_depth + (box_filter_has_retaining_wall ? retaining_depth : 0) : 0)])
            swoop_slice();
    }

    if (include_dovetail) {
        dovetail_length = dovetail_clip_length();
        translate([-dovetail_length / 2 - interspace, 0, dimensions[2]])
        rotate([0, 0, 90])
        dovetail_clip();
    }
}

module fan_slice() {
    thickness = fan_depth + ((fan_has_retaining_wall || fan_has_retaining_lip) ? retaining_depth : 0);
    active_space = [fan_width, fan_height];

    difference() {
        slice_with_void(thickness, active_space);
        if (include_wiring_channel) {
            translate([0, -fan_height / 2 + 29, thickness - 6 + slop])
                cube([fan_width, 4, 6]);
        }
    }
    if (fan_has_retaining_wall)
        retaining_wall();
    if (fan_has_retaining_lip)
        retaining_lip(active_space);
}

module box_filter_slice() {
    thickness = box_filter_depth + ((box_filter_has_retaining_wall || box_filter_has_retaining_lip) ? retaining_depth : 0);
    active_space = [box_filter_width, box_filter_height];

    slice_with_void(thickness, active_space);
    if (box_filter_has_retaining_wall)
        retaining_wall();
    if (box_filter_has_retaining_lip)
        retaining_lip(active_space);
}

module swoop_slice() {
    thickness = swoop_depth;
    //active_space = [large_cutout_length, 0];

    dimensions = loaf_dimensions();
    // Note that we XZ becomes XY here, there is no ~~spoon~~ Z yet.
    X = dimensions[0];
    Y = dimensions[2];
    active_space = [X - 2 * outer_wall_minimum, Y - 2 * outer_wall_minimum];

    difference() {
        union() {
            difference() {
                // slice(thickness);
                translate([-active_space.x / 2, -active_space.y / 2, 0]) 
                cube([active_space.x, active_space.y, thickness]);

                linear_extrude(max(thickness, retaining_depth, dimensions[1]) + slop, convexity = 10)
                    hex_grid(retaining_hex_radius, retaining_hex_edge_width, dimensions[0], dimensions[2]);
            }
            slice_with_void(thickness, active_space);

            translate([0, 0, thickness])
            difference() {
                rotate([90, 0, 0])
                {
                    rotate_extrude(angle = swoop_angle, start = 0, convexity = 10)
                    union() {
                        difference() {
                            polygon([
                                [0, -active_space.y / 2],
                                [active_space.x / 2, -active_space.y / 2],
                                [active_space.x / 2, active_space.y / 2],
                                [0, active_space.y / 2]
                            ]);
                            hex_grid(retaining_hex_radius, retaining_hex_edge_width, dimensions[0], dimensions[2]);
                        }
                        difference() {
                            slice_shape_2d();
                            // Remove the inner part of the slice_shape_2d so the hex grid is visible
                            polygon([
                                [-active_space.x / 2, -active_space.y / 2],
                                [active_space.x / 2, -active_space.y / 2],
                                [active_space.x / 2, active_space.y / 2],
                                [-active_space.x / 2, active_space.y / 2]
                            ]);
                            // Remove the left half of the slice_shape_2d
                            translate([-X / 2 + slop, 0, 0])
                                square([X, 2 * Y], center = true);
                        }
                    }
                }
                dovetail_mask(4 * thickness);
            }
        }
        translate([0, X, thickness])
            rotate([90, 0, 0])
            linear_extrude(height = 2 * Y, convexity = 10)
            hull() {
                translate([-X / 2, 0, thickness])
                    circle(r = X / 2);
                translate([-X, 0, thickness])
                    circle(r = X / 2);
            }
    }
}

module dovetail_clip() {
    length = dovetail_clip_length();

    translate([0, length / 2, 0])
        rotate([90, 0, 0])
        linear_extrude(length) 
        dovetail_shape_2d(-0.4);
}

function dovetail_clip_length() = 
    (include_fan_slice ? fan_depth + (fan_has_retaining_wall ? retaining_depth : 0) : 0)
    + (include_box_filter_slice ? box_filter_depth + (box_filter_has_retaining_wall ? retaining_depth : 0) : 0)
    + (include_swoop_slice ? swoop_depth - loaf_dimensions()[0] / 2 : 0);

//= === === === === === === === === === === === === === === === === === === ===
// Common Parts

module retaining_wall() 
{
    dimensions = loaf_dimensions();
    difference() {
        slice(retaining_depth); 
        translate([0, 0, -slop])
            linear_extrude(max(retaining_depth, dimensions[1]) + slop, convexity = 10)
            hex_grid(retaining_hex_radius, retaining_hex_edge_width, dimensions[0], dimensions[2]);
    }
}

module retaining_lip(active_space) {
    dimensions = loaf_dimensions();
    difference() {
        slice(retaining_depth);
        translate([0, 0, -slop])
            linear_extrude(max(retaining_depth, dimensions[1]) + slop, convexity = 10)
            square([active_space[0] - 2 * retaining_lip_inset, active_space[1] - 2 * retaining_lip_inset], center = true);
    }
}

module hex_grid(radius, edge_width, width, height) {
    // No idea where 1.33975 comes, discovered it empirically.
    equivalent_edge_width = max(-1.53975, edge_width - 1.33975);
    total_r = radius + (equivalent_edge_width * 0.5); // The shortest leg
    // A 30-60-90 triangle, where the shortest leg is the total radius.
    // The Longer leg (opposite the 60° angle) is always the shortest leg multiplied by
    // the square root of 3.
    col_spacing = 2 * total_r * sqrt(3);
    row_spacing = 2 * total_r;
    // Used to render the offset hexagons in the same pass
    secondary_row_spacing = total_r * sqrt(3);

    rows = ceil(height / row_spacing) + 1;
    cols = ceil(width / col_spacing) + 1;

    // translate([-(width + radius) / 2 + equivalent_edge_width, -(height + radius) / 2 + equivalent_edge_width / 2, 0])
    for (row = [-rows:rows]) {
        for (col = [-cols:cols]) {
    // for (row = [0:rows-1]) {
    //     for (col = [0:cols-1]) {
            x = col * col_spacing + (col_spacing * 0.5);
            y = row * row_spacing + (row_spacing * 0.5);
            translate([x, y])
                circle(radius, $fn=6);
            translate([x + secondary_row_spacing, y + total_r])
                circle(radius, $fn=6);
        }
    }
}

//= === === === === === === === === === === === === === === === === === === ===
// Basic Shapes

module slice_with_void(thickness, active_space) {
    difference() {
        slice(thickness);
        translate([0, 0, -slop])
            cube([active_space[0], active_space[1], 4 * thickness], center = true);
    }
}

// Untranslated slice of the fan filter stack, such that the ojects XZ plane is
// parallel to the XY plane, and the Y axis is the depth of the slice.
module slice(thickness) {
    difference() {
        union() {
            linear_extrude(thickness, convexity = 10)
                slice_shape_2d();
            if (include_feet)
                linear_extrude(thickness, convexity = 10)
                feet_shape_2d();
        }
        dovetail_mask(thickness);
    }
}

module slice_shape_2d() {
    dimensions = loaf_dimensions();
    // Note that we XZ becomes XY here, there is no ~~spoon~~ Z yet.
    X = dimensions[0];
    Y = dimensions[2];

    corner_inset_offset = [
        X / 2 - outer_wall_corner_radius,
        Y / 2 - outer_wall_corner_radius,
        0
    ];

    hull()
        four_corners(corner_inset_offset)
        circle(outer_wall_corner_radius);
}

module feet_shape_2d() {
    dimensions = loaf_dimensions();
    // Note that we XZ becomes XY here, there is no ~~spoon~~ Z yet.
    X = dimensions[0];
    Y = dimensions[2];

    feet_outside_radius = feet_inside_radius + outer_wall_minimum;
    feet_projection = [
        X / 2 + feet_inside_radius,
        Y / 2 - feet_inside_radius - outer_wall_minimum,
        0
    ];

    difference() {
        hull()
        {
            circle(1);
            translate([-feet_projection.x, -feet_projection.y, 0])
                circle(feet_outside_radius);
            translate([feet_projection.x, -feet_projection.y, 0])
                circle(feet_outside_radius);
        }
        translate([-feet_projection.x, -feet_projection.y, 0])
            circle(feet_inside_radius);
        translate([feet_projection.x, -feet_projection.y, 0])
            circle(feet_inside_radius);
    }
}

module dovetail_mask(thickness) {
    dimensions = loaf_dimensions();
    // Note that we XZ becomes XY here, there is no ~~spoon~~ Z yet.
    X = dimensions[0];
    Y = dimensions[2];

    offset = [X / 2, Y / 2, 0];

    if (include_dovetail)
        translate([0, 0, -slop])
        linear_extrude(2 * thickness , convexity = 10)
        four_sides(offset)
        dovetail_shape_2d();
}

module dovetail_shape_2d(adjust = 0) {
    // A dovetail shape, used for the dovetail clip.
    // The shape is centered on the origin, and is oriented such that the
    // base of the dovetail is along the X axis.
    width = dovetail_width + adjust; // Width of the dovetail triangle base
    h = width * sqrt(3) / 2; // Height of the dovetail triangle
    difference() {
        polygon([
            [-width / 2, -dovetail_depth],
            [width / 2, -dovetail_depth],
            [0, h]
        ]);
        polygon([
            [-width / 2, slop],
            [width / 2, slop],
            [0, h + slop]
        ]);
    }
}

//= === === === === === === === === === === === === === === === === === === ===
// Logical Maths

function loaf_dimensions() = [
    // Max width of any active slice
    max(
        include_fan_slice
            ? fan_width + 2 * outer_wall_minimum
            : 0,
        include_box_filter_slice
            ? box_filter_width + 2 * outer_wall_minimum
            : 0
        ),
    // The overall depth is cumulative, so addition is used instead of max.
    (include_fan_slice
        ? fan_depth + (fan_has_retaining_wall ? retaining_depth : 0)
        : 0)
    + (include_box_filter_slice
        ? box_filter_depth + (box_filter_has_retaining_wall ? retaining_depth : 0)
        : 0),
    // Max height of any active slice
    max(
        include_fan_slice
            ? fan_height + 2 * outer_wall_minimum
            : 0,
        include_box_filter_slice
            ? box_filter_height + 2 * outer_wall_minimum
            : 0
        )
];

//= === === === === === === === === === === === === === === === === === === ===
// Utilities

// Offsets is an [x,y,x] value. Places a copy of the children at all four corners
// of the base, offset by the given x and y values. The z value is ignored
// and is only there to match the signature of the other modules.
// This is useful for placing the clip at the four corners of the base.
// The offsets are relative to the center of the base. the children will be
// rotated and mirrored as needed to fit in the corners.
module four_corners(offset) {
    // near
    translate([-offset.x, -offset.y, offset.z])
        rotate([0, 0, 0]) 
        children();
    translate([offset.x, -offset.y, offset.z])
        mirror([1, 0, 0]) 
        children();
    // far
    translate([offset.x, offset.y, offset.z])
        rotate([0, 0, 180]) 
        children();
    translate([-offset.x, offset.y, offset.z])
        rotate([0, 0, 180]) 
        mirror([1, 0, 0]) 
        children();
}

module four_sides(offset) {
    // offset is [x, y, z]
    // The x and y values are the offsets from the center of the base.
    // The z value is ignored and is only there to match the signature of the other modules.
    translate([0, offset.y, offset.z])
        rotate([0, 0, 0]) 
        children();
    translate([0, -offset.y, offset.z])
        rotate([0, 0, 180]) 
        children();
    translate([offset.x, 0, offset.z])
        rotate([0, 0, -90]) 
        children();
    translate([-offset.x, 0, offset.z])
        rotate([0, 0, 90]) 
        children();
}

module four_corners_mirrored(offset) {
    // near
    translate([-offset.x, -offset.y, offset.z])
        rotate([0, 0, 0]) 
        children();
    translate([offset.x, -offset.y, offset.z])
        mirror([1, 0, 0]) 
        children();
    // far
    translate([offset.x, offset.y, offset.z])
        rotate([0, 0, 180]) 
        children();
    translate([-offset.x, offset.y, offset.z])
        rotate([0, 0, 180]) 
        mirror([1, 0, 0]) 
        children();
}
