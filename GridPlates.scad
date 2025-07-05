// Author: https://makerworld.com/en/@TooManyThings
// Link: https://makerworld.com/en/models/<todo>
// License: MIT

// Based on: 
// Link: https://makerworld.com/en/models/476846
// Author: https://makerworld.com/@LayerCake
// License: MIT

// Based on the excellent Gridfinity system by Zach Freedman
// Wiki: https://gridfinity.xyz/

// Differeces from the standard design:
//  - The interface has an added 0.4 mm flat section on top.
//  - The bottom chamfer has been extended for improved print bed adhesion.
//  - The base units can be overwritten which breaks compatibility but can use all space available.

// Enter measured size in mm, or, number of Gridfinity units x 42.
Width = 325;

// Enter measured size in mm, or, number of Gridfinity units x 42.
Depth = 275;

// Suggest 2mm where measurements don't already allow for clearance.
Clearance = 0;

Build_Plate_Size=236; //[180: Small (A1 Mini), 236: Standard (X1/P1/A1), 350: Large (350mm)]

// Include a half-width grid in the margin(s) if there is sufficient space.
Half_Sized_Filler = true;

// In mm. Use with caution as this will increase warping.
Solid_Base_Thickness = 0;

/* [Advanced] */

// Offset grid right or left in mm.
Offset_Horizontal = 0;

// Offset grid back or forward in mm.
Offset_Vertical = 0;

// When the base plate has margins, add additional rounding to the base plate corners. The larger the margins, the more extra rounding.
Extra_Corner_Rounding = true;

// When disabled, a normal butt-together baseplate will be generated.
Generate_Locking_Tabs = true;

// Mirrors the baseplate left-to-right.
Mirror = false;

// Standard Gridfinity is 42 mm
Base_Unit_Width_Depth = 42;

/* [Hidden] */

// Default: 4 mm (Minimum: 4 mm)
Base_Unit_Radius = 4;

// Calculate unit counts, margins and whether we have half strips.
adjusted_width = Width - Clearance;
adjusted_depth = Depth - Clearance;

whole_units_wide = floor(adjusted_width / Base_Unit_Width_Depth);
whole_units_deep = floor(adjusted_depth / Base_Unit_Width_Depth);

have_vertical_half_strip = 
    Half_Sized_Filler && 
    (adjusted_width - whole_units_wide * Base_Unit_Width_Depth) >= Base_Unit_Width_Depth / 2;
have_horizontal_half_strip = 
    Half_Sized_Filler &&
    (adjusted_depth - whole_units_deep * Base_Unit_Width_Depth) >= Base_Unit_Width_Depth / 2;
units_wide = whole_units_wide + (have_vertical_half_strip ?  0.5 : 0);
units_deep = whole_units_deep + (have_horizontal_half_strip ?  0.5 : 0);
    
half_margin_h = (adjusted_width - units_wide * Base_Unit_Width_Depth) / 2;
half_margin_v = (adjusted_depth - units_deep * Base_Unit_Width_Depth) / 2;
margin_left = half_margin_h + Offset_Horizontal;
margin_top = half_margin_v + Offset_Vertical;
margin_right = half_margin_h - Offset_Horizontal;
margin_bottom = half_margin_v - Offset_Vertical;

radius_front_left = Base_Unit_Radius + (Extra_Corner_Rounding ? min(margin_left, margin_bottom): 0);
radius_back_left = Base_Unit_Radius + (Extra_Corner_Rounding ? min(margin_left, margin_top): 0);
radius_back_right = Base_Unit_Radius + (Extra_Corner_Rounding ? min(margin_right, margin_top): 0);
radius_front_right = Base_Unit_Radius + (Extra_Corner_Rounding ? min(margin_right, margin_bottom): 0);

fn_min = 20;
fn_max = 40;
function lerp(x, x0, x1, y0, y1) = y0 + (x - x0) * (y1 - y0) / (x1 - x0);
$fn = max(min(lerp(units_wide*units_deep, 200, 400, fn_max, fn_min), fn_max), fn_min);

max_unit_dimension = max(units_wide, whole_units_wide, whole_units_deep);

// Base Unit Width/Depth
b_xy = Base_Unit_Width_Depth;
// Base Radius
b_r = Base_Unit_Radius;

// Interface Top Flat
i_t_f = 0.4;
// Interface Top Chamfer
i_t_c = 1.75;
// Interface Middle Height
i_m_h = 1.8;
// Interface Bottom Chamfer
i_b_c = 1.05;
// Interface Overall Height
i_h = i_t_c + i_m_h + i_b_c;

// Need to increase as the cutting tool intentionally extends deeper than necessary.
extra_base_thickness = Solid_Base_Thickness > 0 ? Solid_Base_Thickness + 0.5 : 0;

max_recursion_depth = 12;
part_spacing = 10;

cutting_start_offset = [-b_xy*units_wide/2, -b_xy*units_deep/2, 0];
interface_offset = cutting_start_offset + [b_xy*0.5, b_xy*0.5, 0];

// Entry point
if (Mirror) {
    mirror([1, 0, 0]) {
        RecursiveCutX() {
            GridfinityBasePlate();
        }
    }
} else {
    RecursiveCutX() {
        GridfinityBasePlate();
    }
}

module RecursiveCutX(prev_offset = 0, depth = 0) {
    offset = GetCutOffsetForward(prev_offset, margin_left, margin_right, units_wide);
    
    alt_y_cuts = depth % 2 != 0;
    
    if (offset < 0 || depth > max_recursion_depth) {
        // We've reached the end or recursing too much, use remaining body.
        translate([part_spacing * depth, 0, 0]) {
            RecursiveCutY(alt_y_cuts) {
                children();
            }
        }
    } else {
        // Cut the body
        // Left body
        translate([part_spacing * depth, 0, 0]) {
            RecursiveCutY(alt_y_cuts) {
                intersection() {
                    children();
                    translate([offset * Base_Unit_Width_Depth, 0, 0]) cutting_tool_left();
                }
            }
        }
        
        // Recursively cut the right body
        RecursiveCutX(offset, depth + 1) {
            intersection() {
                children();
                translate([offset * Base_Unit_Width_Depth, 0, 0]) cutting_tool_right();
            }
        }
    }
}

module RecursiveCutY(alt_cuts, prev_offset = 0, depth = 0) {
    standard_offset = GetCutOffsetForward(prev_offset, margin_bottom, margin_top, units_deep);
    offset = alt_cuts && prev_offset==0 && standard_offset >= 0 ? 
        GetAltStartOffset(margin_bottom, margin_top, units_deep) :
        standard_offset;
    
    if (offset < 0 || depth > max_recursion_depth) {
        // We've reached the end or recursing too much, return the remaining body
        translate([0, part_spacing * depth, 0]) {
            children();
        }
    } else {
        // Cut the body
        // Bottom body
        translate([0, part_spacing * depth, 0]) {
            intersection() {
                children();
                translate([0, offset * Base_Unit_Width_Depth, 0]) 
                    cutting_tool_bottom();
            }
        }
        
        // Recursively cut the top body
        RecursiveCutY(alt_cuts, offset, depth + 1) {
            intersection() {
                children();
                translate([0, offset * Base_Unit_Width_Depth, 0]) 
                    cutting_tool_top();
            }
        }
    }
}

function GetCutOffsetForward(prev_offset, margin_start, margin_end, axis_unit_length) =
    let(
        prev_carry_over = prev_offset == 0 ? margin_start : left_tab_extent,
        remaining = prev_carry_over + (axis_unit_length - prev_offset) * Base_Unit_Width_Depth + margin_end,
        next_offset = prev_offset + floor((Build_Plate_Size - left_tab_extent - right_tab_extent - (prev_offset == 0 ? margin_start : 0)) / Base_Unit_Width_Depth),
        next_remaining_approx = (axis_unit_length - next_offset) * Base_Unit_Width_Depth + margin_end
    )
       
    remaining <= Build_Plate_Size ? -1 :
    (next_remaining_approx < Base_Unit_Width_Depth + tab_needed_vertical_extent) ? next_offset - 1 :
    next_offset;

function GetAltEndOffset(margin_end, axis_unit_length) =
    let(
        space_for_full_units = Build_Plate_Size - margin_end - left_tab_extent - (axis_unit_length % 1) * Base_Unit_Width_Depth,
        full_units = floor(space_for_full_units / Base_Unit_Width_Depth),
        offset = floor(axis_unit_length) - full_units
    )
    offset;

function GetUnitsPerInnerSection(axis_unit_length) =
    let(
        space_for_full_units = Build_Plate_Size - left_tab_extent - right_tab_extent
    )
    floor(space_for_full_units / Base_Unit_Width_Depth);

function GetAltStartOffset(margin_start, margin_end, axis_unit_length) =
    let(
        end_offset = GetAltEndOffset(margin_end, axis_unit_length),
        units_per_inner_section = GetUnitsPerInnerSection(axis_unit_length),
        initial_offset = end_offset % units_per_inner_section,
        adjusted_offset = 
            (initial_offset == 0) ?
                (Base_Unit_Width_Depth * units_per_inner_section + right_tab_extent + margin_start <= Build_Plate_Size) ?
                    units_per_inner_section : 1
            : initial_offset,
        final_offset = 
            (adjusted_offset == 1 && margin_start < tab_needed_vertical_extent) ?
                2 : adjusted_offset
    )
    final_offset;
  
module GridfinityBasePlate()
{
    difference() {
        // Grid
        g_w = b_xy * units_wide;
        g_d = b_xy * units_deep;
        // Main Body
        mb_w = g_w + margin_left + margin_right;
        mb_d = g_d + margin_top + margin_bottom;

        base_height = i_h + extra_base_thickness;
        translate([-g_w/2-margin_left,-g_d/2-margin_bottom, - extra_base_thickness]) {
            difference() {
                cube([mb_w, mb_d, base_height]);
                CornerChamferCutter(radius_front_left, base_height);
                translate([0,mb_d,0]) {
                    mirror([0,1,0]) {
                        CornerChamferCutter(radius_back_left, base_height);
                    }
                }
                translate([mb_w,mb_d,0]) {
                    mirror([1,1,0]) {
                        CornerChamferCutter(radius_back_right, base_height);
                    }
                }
                translate([mb_w,0,0]) {
                    mirror([1,0,0]) {
                        CornerChamferCutter(radius_front_right, base_height);
                    }
                }
            }
        }
        // Interface Pattern
        translate(interface_offset) {
            for(w=[1:ceil(units_wide)]) {
                for(d=[1:ceil(units_deep)]) {
                    translate([b_xy*(w-1), b_xy*(d-1),0]) {
                        GridfinityInterface(w > units_wide ? 0.5 : 1, d > units_deep ? 0.5 : 1);
                    }
                }
            }
        }
    }
}

module GridfinityInterface(x_scale, y_scale) {
    translate([(x_scale-1)*0.5*b_xy,(y_scale-1)*0.5*b_xy]) {
        union() {
            translate([0,0,-0.5]) {
                BottomChamferedRoundedSquare(b_xy*x_scale-(i_t_f+i_t_c)*2, b_xy*y_scale-(i_t_f+i_t_c)*2, i_b_c+i_m_h+1.5, b_r-(i_t_f+i_t_c), i_b_c+0.5);
            }
            translate([0,0,i_b_c+i_m_h]) {
                BottomChamferedRoundedSquare(b_xy*x_scale-i_t_f, b_xy*y_scale-i_t_f, i_t_c+0.5, b_r-i_t_f, i_t_c+0.5);
            }
        }
    }
}

module CornerChamferCutter(radius, height) {
    translate([radius,radius,0]) {
        mirror([1,1,0]) {
            difference() {
                translate([0,0,-1]) {
                    cube([radius*2, radius*2, height+2]);
                }
                translate([0,0,-2]) {
                    cylinder(h=height+4,r=radius);
                }
            }
        }
    }
}

module RoundedSquare(width, depth, height, radius) {
    minkowski() {
        rs_x = width - radius * 2;
        rs_y = depth - radius * 2;
        XYCenteredCube(rs_x, rs_y, height/2);
        cylinder(r=radius, h=height/2);
    }
}

module BottomChamferedRoundedSquare(width, depth, height, radius, chamfer){
    union() {
        difference() {
            // larger/straight dimensions
            l_x = width/2;
            l_y = depth/2;
            // smaller/chamfered dimensions
            s_x = l_x - chamfer;
            s_y = l_y - chamfer;
            polyhedron(
                points=[[s_x,s_y,0], [s_x,-s_y,0], [-s_x,-s_y,0], [-s_x,l_y-chamfer,0], // base
                        [l_x,l_y,chamfer], [l_x,-l_y,chamfer], [-l_x,-l_y,chamfer], [-l_x,l_y,chamfer], //middle
                        [l_x,l_y,height], [l_x,-l_y,height], [-l_x,-l_y,height], [-l_x,l_y,height]], //top 
                faces=[[3,2,1,0], // base
                       [5,4,0,1], [4,7,3,0], [7,6,2,3], [6,5,1,2], // angled sides
                       [9,8,4,5], [8,11,7,4], [11,10,6,7], [10,9,5,6], // straight sides
                       [11,8,9,10]] // top
            );
            // Cutout Corners
            rcs_c1x = width / 2 - radius / 2 + 1;
            rcs_c1y = depth / 2 - radius / 2 + 1;
            translate([rcs_c1x,rcs_c1y,height/2]) {
                cube([radius+2, radius+2, height+1], true);
            }
            translate([rcs_c1x,-rcs_c1y,height/2]) {
                cube([radius+2, radius+2, height+1], true);
            }
            translate([-rcs_c1x,-rcs_c1y,height/2]) {
                cube([radius+2, radius+2, height+1], true);
            }
            translate([-rcs_c1x,rcs_c1y,height/2]) {
                cube([radius+2, radius+2, height+1], true);
            }
        }
        // Rounded Corners
        rcs_c2x = width / 2 - radius;
        rcs_c2y = depth / 2 - radius;
        // Chamfer
        translate([rcs_c2x,rcs_c2y,0]) {
            BottomChamferedCylinder(radius, height, chamfer);
        }
        translate([rcs_c2x,-rcs_c2y,0]) {
            BottomChamferedCylinder(radius, height, chamfer);
        }
        translate([-rcs_c2x,-rcs_c2y,0]) {
            BottomChamferedCylinder(radius, height, chamfer);
        }
        translate([-rcs_c2x,rcs_c2y,0]) {
            BottomChamferedCylinder(radius, height, chamfer);
        }
    }
}

module BottomChamferedCylinder(radius, height, chamfer) {
    difference() {
        cylinder(h=height, r=radius);
        difference() {
            translate([0,0,-1]) {
                cylinder(h=chamfer+1, r=radius+1);
            }
            cylinder(h=chamfer*2, r1=radius-chamfer, r2=radius+chamfer);
        }
    }
}

module XYCenteredCube(width, depth, height) {
    translate([-width/2,-depth/2,0]) {
        cube([width, depth, height]);
    }
}

// Tessellation functions
function tessellate_arc(start, end, bulge, segments = 8) =
    let(
        chord = end - start,
        chord_length = norm(chord),
        sagitta = abs(bulge) * chord_length / 2,
        radius = (chord_length/2)^2 / (2*sagitta) + sagitta/2,
        center_height = radius - sagitta,
        center_offset = [-chord.y, chord.x] * center_height / chord_length,
        center = (start + end)/2 + (bulge >= 0 ? center_offset : -center_offset),
        start_angle = atan2(start.y - center.y, start.x - center.x),
        end_angle = atan2(end.y - center.y, end.x - center.x),
        angle_diff = (bulge >= 0) ?
            (end_angle < start_angle ? end_angle - start_angle + 360 : end_angle - start_angle) :
            (start_angle < end_angle ? start_angle - end_angle + 360 : start_angle - end_angle),
        num_segments = max(1, round(segments * (angle_diff / 360))),
        angle_step = angle_diff / num_segments
    )
    [for (i = [0 : num_segments - 1])
        let(angle = start_angle + (bulge >= 0 ? 1 : -1) * i * angle_step)
        center + radius * [cos(angle), sin(angle)]
    ];
    
function tessellate_polyline(data, segments = 8) =
    let(
        points = [for (i = [0:len(data)-1])
            let(
                start = [data[i][0], data[i][1]],
                end = [data[(i+1) % len(data)][0], data[(i+1) % len(data)][1]],
                bulge = data[i][2]
            )
            if (bulge == 0)
                [start]
            else
                tessellate_arc(start, end, bulge, segments)
        ]
    )
    [for (segment = points, point = segment) point];
        
// Profile data (as provided before)
function reverse_polyline_data(data) = 
    let(
        n = len(data),
        reversed = [for (i = [n-1:-1:0]) 
            [data[i][0], data[i][1], 
             i > 0 ? -data[i-1][2] : 0]  // Negate bulge from previous point
        ]
    )
    reversed;
       
polyline_data_1 = [
    [0.2499999999999975, 38.523373536222223, 0.13165249758739542],
    [0.17229473419497243, 38.813373536222223, 0],
    [-0.77549874656872519, 40.454999999987507, -0.76732698797895982],
    [-0.43399239561125647, 40.796506350944981, 0],
    [0.44430391496627875, 40.289421739604791, 0.57735026918962284],
    [1.0743039149299163, 40.653152409173259, 0]
];

polyline_data_2 = [
    [0.90430391492990991, 40.653152409173259, -0.57735026918962595],
    [0.52930391496627871, 40.436646058248151, 0],
    [-0.3489923956112484, 40.943730669588334, 0.76732698797896193],
    [-0.92272306521208713, 40.369999999987513, 0],
    [-0.28349364905389146, 39.262822173508923, -0.13165249758738012],
    [-0.25000000000000011, 39.137822173508923, 0]
];

polyline_data_1_no_tab = [
    [0.2499999999999975, 38.523373536222223, 0],
    [0.2499999999999975, 40.653152409173259, 0]
];

polyline_data_2_no_tab = [
    [-0.25000000000000011, 40.653152409173259, 0],
    [-0.25000000000000011, 39.137822173508923, 0]
];



function get_min_polyline_x(data, segments = 8) =
    min([for (point = tessellate_polyline(data, segments)) point[0]]);

function get_max_polyline_x(data, segments = 8) =
    max([for (point = tessellate_polyline(data, segments)) point[0]]);
    
left_tab_extent = -min(0, min(get_min_polyline_x(polyline_data_1), get_min_polyline_x(polyline_data_2)));
right_tab_extent = max(0, max(get_max_polyline_x(polyline_data_1), get_max_polyline_x(polyline_data_2)));
tab_needed_vertical_extent = 3; // Need approx. 3mm each side for a decent tab.
reversed_polyline_data_2 = reverse_polyline_data(polyline_data_2);    
reversed_polyline_data_2_no_tab = reverse_polyline_data(polyline_data_2_no_tab);    

function modify_and_mirror_profile(data) =
    let(
        tessellated = tessellate_polyline(data),
        shifted = [for (point = tessellated) [point.x, point.y - 42]],
        mirrored = [for (point = reversed(shifted)) [point.x, -point.y]],
        connection_point = shifted[len(shifted)-1],
        mirrored_connection = [connection_point.x, -connection_point.y]
    )
    [
        each shifted,
        mirrored_connection,
        each mirrored
    ];

// Helper function to reverse an array
function reversed(arr) = [for (i = [len(arr)-1:-1:0]) arr[i]];

function repeat_profile(profile, repetitions) =
    let(
        repeated = [for (i = [0:repetitions-1])
            [for (point = profile)
                [point.x, point.y + i * Base_Unit_Width_Depth]
            ]
        ]
    )
    [for (segment = repeated, point = segment) point];

module extend_profile(data, direction, repetitions=max_unit_dimension+1) {
    modified = modify_and_mirror_profile(data);
    repeated = repeat_profile(modified, repetitions);
    n = len(repeated);
    
    extension = (max_unit_dimension+2) * Base_Unit_Width_Depth * direction;
        
    down_ext = repeated[0] + [0, -Base_Unit_Width_Depth];
    up_ext = repeated[n-1] + [0, Base_Unit_Width_Depth];

    start_ext = down_ext + [extension, 0];
    end_ext = up_ext + [extension, 0];
        
    polygon([
        start_ext,
        down_ext,
        each repeated,
        up_ext,
        end_ext,
        [end_ext.x, start_ext.y]
    ]);
}

module cutting_profile_1() {
    extend_profile(Generate_Locking_Tabs ? reversed_polyline_data_2 : reversed_polyline_data_2_no_tab, -1);   // Extend to the left.
}

module cutting_profile_2() {
    extend_profile(Generate_Locking_Tabs ? polyline_data_1 : polyline_data_1_no_tab, 1);  // Extend to the right.
}

cutting_tool_height = max(i_h, extra_base_thickness) * 4;

module cutting_tool_left() {
    translate(cutting_start_offset) {
        linear_extrude(height=cutting_tool_height, center=true) cutting_profile_1();
    }
}

module cutting_tool_right() {
    translate(cutting_start_offset) {
        linear_extrude(height=cutting_tool_height, center=true) cutting_profile_2();
    }
}

module cutting_tool_bottom() {
    translate(cutting_start_offset) {
        rotate([0, 0, -90])
            linear_extrude(height=cutting_tool_height, center=true) cutting_profile_2();
    }
}

module cutting_tool_top() {
    translate(cutting_start_offset) {
        rotate([0, 0, -90])
            linear_extrude(height=cutting_tool_height, center=true) cutting_profile_1();
    }
}