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

/*[Fan Slice]*/
// Include the Fan Slice
include_fan_slice = true; // [true: Include the fan slice, false: Exclude the fan slice]
// Width (x) of the fan slice
fan_width = 120.1;
// Depth (y) of the fan slice
fan_depth = 25.3;
// Height (z) of the fan slice
fan_height = 120.1;
// Include wireing channel
include_wiring_channel = true; // [true: Include the wiring channel, false: Exclude the wiring channel]
// Fan slice has retaining wall
fan_has_retaining_wall = true; // [true: Fan slice has retaining wall, false: No retaining wall]
// Fan slice has retaining lip
fan_has_retaining_lip = true; // [true: Fan slice has retaining edge, false: No retaining edge]

/*[Box Filter Slice]*/
include_box_filter_slice = true; // [true: Include the box filter slice, false: Exclude the box filter slice]
// Width (x) of the box filter slice
box_filter_width = 120;
// Depth (y) of the box filter slice
box_filter_depth = 25;
// Height (z) of the box filter slice
box_filter_height = 120;
// Box filter slice has retaining wall
box_filter_has_retaining_wall = true; // [true: Box filter slice has retaining wall, false: No retaining wall]


/*[Outer Walls]*/
// Minimum wall thinckness
outer_wall_minimum = 3.5;
// Corner radius (r)
outer_wall_corner_radius = 5.2;

/*[Common Features]*/
// Retaining wall and/or lip depth (y)
retaining_depth = 1.2;
// Retaining wall radius (r)
retaining_wall_radius = 6.5;
// retaining wall edge width
retaining_wall_edge_width = 0.1; // [0.1:0.1:5]
// retaining lip inset
retaining_lip_inset = 1.5;
// Include feet
include_feet = true; // [true: Include the feet, false: Exclude the feet]
// Feet inside radius (r)
feet_inside_radius = 8.1;

/*[Hidden]*/
large_cutout_length = 200;
$fn = 128;
_sqrt2 = sqrt(2);
slop = 0.01; // Small offset to avoid z-fighting

//= === === === === === === === === === === === === === === === === === === ===
// Main

main();

module main() {
    fan_slice();
}

module fan_slice() {
    slice_thickness = fan_depth + ((fan_has_retaining_wall || fan_has_retaining_lip) ? retaining_depth : 0);
    active_space = [fan_width, fan_height];

    difference() {
        slice_with_void(slice_thickness, active_space);
        if (include_wiring_channel) {
            translate([0, -fan_height / 2 + 30, slice_thickness - 5])
                cube([fan_width, 3, 6]);
        }
    }
    if (fan_has_retaining_wall)
        retaining_wall();
    if (fan_has_retaining_lip)
        retaining_lip(active_space);
}

module retaining_wall() 
{
    dimensions = loaf_dimensions();
    difference() {
        slice(retaining_depth); 
        translate([0, 0, -slop])
            linear_extrude(max(retaining_depth, dimensions[1]) + slop, convexity = 10)
            hex_grid(retaining_wall_radius, retaining_wall_edge_width, dimensions[0], dimensions[2]);
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
    // A 30-60-90 triangle, whre the shortest leg is the total radius.
    // The Longer leg (opposite the 60° angle) is alwaysthe shortest leg multiplied by
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
    dimensions = loaf_dimensions();
    // echo(dimensions);

    offset = [
        dimensions[0] / 2 - outer_wall_corner_radius,
        dimensions[2] / 2 - outer_wall_corner_radius,
        0
    ];
    // echo(offset);
    
    feet_outside_radius = feet_inside_radius + outer_wall_minimum;
    feet_projection_x = dimensions[0] / 2 + feet_inside_radius;
    feet_projection_y = dimensions[2] / 2 - feet_inside_radius - outer_wall_minimum;
    // echo([feet_projection_x, feet_projection_y]);

    union() {
        linear_extrude(thickness, convexity = 10)
            hull()
            four_corners(offset)
            circle(outer_wall_corner_radius);
        if (include_feet)
            linear_extrude(thickness, convexity = 10)
            difference() {
                #hull()
                {
                    circle(1);
                    translate([-feet_projection_x, -feet_projection_y, 0])
                        circle(feet_outside_radius);
                    translate([feet_projection_x, -feet_projection_y, 0])
                        circle(feet_outside_radius);
                }
                translate([-feet_projection_x, -feet_projection_y, 0])
                    circle(feet_inside_radius);
                translate([feet_projection_x, -feet_projection_y, 0])
                    circle(feet_inside_radius);
            }
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
        rotate([0, 0, 90]) 
        children();
    translate([-offset.x, 0, offset.z])
        rotate([0, 0, -90]) 
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
