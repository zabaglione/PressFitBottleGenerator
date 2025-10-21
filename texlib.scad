// texlib.scad  ——  Texturing helper library (revised)
// License: MIT
// Dependencies: BOSL2 (std.scad)
include <BOSL2/std.scad>;

// ---------- helpers ----------
function _clamp(x,a,b)=max(a,min(b,x));
function _is_custom_tex(name) = (name=="asanoha" || name=="seigaiha" || name=="diagonal_ribs" || name=="polar_waves");

function _border_ok(b) = is_undef(b) ? false : ((b > 0) && (b < 0.5));
function _border_safe(b) = min(b, 0.49);

function _supports_border_for_bosl2(texname) =
    // 元作例の注記に合わせる
    (texname=="checkers") ||
    (texname=="cones") ||
    (texname=="hex_grid") ||
    (texname=="trunc_diamonds");

function _is_none_tex(texname) = (texname=="none");

// ---------- custom tile primitives (2D) ----------
module _tile_asanoha(sz=[10,10], stroke=0.4){
    // simplified star lattice with 3 directions
    module _stroke_rect(p1, p2, w){
        v = [p2[0]-p1[0], p2[1]-p1[1]];
        len = norm(v);
        ang = atan2(v[1], v[0]);
        translate(p1) rotate(ang) translate([len/2,0]) square([len,w], center=true);
    }
    scale([sz[0], sz[1], 1]){
        _stroke_rect([0.0,0.5],[1.0,0.5], stroke/sz[1]);
        _stroke_rect([0.0,0.0],[1.0,1.0], stroke/sz[1]);
        _stroke_rect([0.0,1.0],[1.0,0.0], stroke/sz[1]);
    }
}

module _tile_seigaiha(sz=[10,10], arc_w=0.15, pitch=0.25){
    scale(sz){
        for (r=[pitch: pitch: 1.0]){
            difference(){
                circle(r=r);
                circle(r=max(0,r-arc_w));
                translate([-1, -1]) square([2,1]); // 上半分を残す
            }
        }
    }
}

module _tile_diagonal_ribs(sz=[10,10], rib_w=0.35, tilt=30){
    rotate(tilt) square([sz[0], rib_w], center=true);
}

module _tile_polar_waves(sz=[10,10], rings=4, ring_w=0.2){
    scale(sz){
        for(i=[1:rings]){
            r = i/(rings+1);
            difference(){
                circle(r=r);
                circle(r=max(0,r-ring_w));
            }
        }
    }
}

// ディスパッチ（2D）
module _call_tile2d(tex_name, sz){
    if (tex_name=="asanoha")      _tile_asanoha(sz=sz);
    else if (tex_name=="seigaiha")      _tile_seigaiha(sz=sz);
    else if (tex_name=="diagonal_ribs") _tile_diagonal_ribs(sz=sz);
    else if (tex_name=="polar_waves")   _tile_polar_waves(sz=sz);
    else square(sz, center=true); // フォールバック
}

// ---------- 側面テクスチャ（円筒） ----------
module side_textured_cylinder(
    d=40, h=30,
    emboss_mode="emboss",       // "emboss" or "deboss"
    tex="hex_grid",             // BOSL2名 or カスタム名("asanoha"...)
    tex_size=[10,10],
    tex_depth=0.6,
    twist=0,
    grad_twist=0,               // 線形追加ツイスト（h方向）
    pad_top=0,
    pad_bottom=0,
    border=0                    // BOSL2 texture() の border に委譲
){
    let(
        _h_band = max(0, h - pad_top - pad_bottom),
        _twist  = twist + grad_twist
    )
    union(){
        // bottom padding
        if (pad_bottom>0)
            cylinder(h=pad_bottom, d=d + (border*2));

        // main band
        translate([0,0,pad_bottom]){
            // 既存 let(...) の中、BOSL2 named texture を委譲するブロック
            // BOSL2 named texture 分岐
            if (!_is_custom_tex(tex)) {
                // none の場合はプレーンシェルで終了
                if (_is_none_tex(tex)) {
                    linear_sweep(circle(d=d), h=_h_band, twist=_twist);
                } else {
                    // border を渡してよいか判定
                    _border_ok = (border > 0) && (border < 0.5) && _supports_border_for_bosl2(tex);
                    if (_border_ok) {
                        linear_sweep(
                            circle(d=d),
                            texture=texture(tex, border=min(border,0.49)),
                            tex_size=tex_size,
                            tex_depth=tex_depth * (emboss_mode=="deboss" ? -1 : 1),
                            h=_h_band,
                            twist=_twist
                        );
                    } else {
                        // border 非対応 or 0/0.5以上は、引数を渡さない
                        linear_sweep(
                            circle(d=d),
                            texture=texture(tex),
                            tex_size=tex_size,
                            tex_depth=tex_depth * (emboss_mode=="deboss" ? -1 : 1),
                            h=_h_band,
                            twist=_twist
                        );
                        // 任意：通知（うるさい場合は削除）
                        if (border>0 && !_supports_border_for_bosl2(tex))
                            echo(str("[info] BOSL2 texture '", tex, "' ignores 'border'."));
                    }
                }
            }
        }

        // top padding
        if (pad_top>0)
            translate([0,0,h-pad_top])
                cylinder(h=pad_top, d=d + (border*2));
    }
}

// カスタムタイルの円筒ラップ（外向き押出）
module _wrap_custom_tiles_around_cylinder(d=40, h=20, tex_name="asanoha", tex_size=[10,10], depth=0.6){
    circ = PI*d;
    cols = max(1, ceil(circ/tex_size[0]));
    rows = max(1, ceil(h/tex_size[1]));
    radius = d/2;

    for (iy=[0:rows-1]){
        z0 = iy*tex_size[1];
        for (ix=[0:cols-1]){
            ang = 360 * (ix/cols);
            translate([0,0,z0])
            rotate([0,0,ang])
            translate([radius,0,0])
                linear_extrude(height=depth)
                    _call_tile2d(tex_name, tex_size);
        }
    }
}

// ---------- 上面テクスチャ（円板） ----------
module top_textured_disk(
    d=40, t=3,
    mode="emboss",              // "emboss"/"deboss"
    tex="hex_grid",             // BOSL2名 or カスタム名
    tex_size=[10,10],
    tex_depth=0.6,
    keep_center=0,              // 中央を無加工で残す半径
    ring_border=0               // 外周の縁取り幅
){
    // ベース
    difference(){
        cylinder(h=t, d=d);
        if (mode=="deboss"){
            if (!_is_custom_tex(tex))
                _apply_planar_bosl2(d=d, depth=tex_depth, tex=tex, tex_size=tex_size);
            else
                _apply_planar_custom(d=d, depth=tex_depth, tex_name=tex, tex_size=tex_size);
        }
        if (keep_center>0)
            translate([0,0,-0.2]) cylinder(h=t+0.4, d=keep_center*2);
    }

    if (mode=="emboss"){
        if (!_is_custom_tex(tex))
            _apply_planar_bosl2(d=d, depth=tex_depth, tex=tex, tex_size=tex_size);
        else
            _apply_planar_custom(d=d, depth=tex_depth, tex_name=tex, tex_size=tex_size);
    }

    if (ring_border>0){
        difference(){
            cylinder(h=t, d=d);
            cylinder(h=t+0.1, d=d-2*ring_border);
        }
    }
}

module _apply_planar_bosl2(d=40, depth=0.6, tex="checkers", tex_size=[10,10]){
    // 正方向押出の薄板に BOSL2 テクスチャを焼き込んで上面に重畳
    // ディスク境界で切り抜き
    difference(){
        linear_sweep(
            square([d*PI, d], center=true),
            h=depth,
            texture=texture(tex),
            tex_size=tex_size,
            tex_depth=depth
        );
        translate([0,0,-0.1]) cylinder(h=depth+0.2, d=d);
    }
}

module _apply_planar_custom(d=40, depth=0.6, tex_name="asanoha", tex_size=[10,10]){
    cols = max(1, ceil((PI*d)/tex_size[0]));
    rows = max(1, ceil(d/tex_size[1]));
    // 平板にタイルを押出し → 円板でクリップ
    intersection(){
        linear_extrude(height=depth)
            union(){
                for (iy=[0:rows-1]) for (ix=[0:cols-1]){
                    translate([ix*tex_size[0] - (cols*tex_size[0])/2,
                               iy*tex_size[1] - (rows*tex_size[1])/2, 0])
                        _call_tile2d(tex_name, tex_size);
                }
            }
        translate([0,0,-0.1]) cylinder(h=depth+0.2, d=d);
    }
}

// ====== add to texlib.scad (or new file) ======
module textured_container(
    d=40,              // 外径
    h=30,              // 全高
    wall=1.6,          // 壁厚
    bottom=2.0,        // 底厚
    emboss_mode="emboss",
    tex="hex_grid",
    tex_size=[10,10],
    tex_depth=0.6,
    twist=0,
    grad_twist=0,
    pad_top=0,
    pad_bottom=0,
    border=0
){
    // 壁厚ガード
    if (emboss_mode=="deboss" && wall < tex_depth + 0.4)
        echo("[warn] wall is thin for deboss: increase wall or decrease tex_depth.");

    // 外形＋底 を作り、内側を差し引く
    difference(){
        // 外形（側面テクスチャ＋底）
        union(){
            side_textured_cylinder(
                d=d, h=h,
                emboss_mode=emboss_mode,
                tex=tex,
                tex_size=tex_size,
                tex_depth=tex_depth,
                twist=twist,
                grad_twist=grad_twist,
                pad_top=pad_top,
                pad_bottom=pad_bottom,
                border=border
            );
            // 底：内径側に少し入れ込んで面を繋げる
            cylinder(h=bottom, d=d - wall);
        }
        // 内側くり抜き（底上がり位置から）
        translate([0,0,bottom])
            cylinder(h=h - bottom + 0.2, d=d - 2*wall);
    }
}

// 押し込み式フタ（Press-fit）
module pressfit_lid(
    d=40,               // 対象容器 外径
    wall=1.6,           // 容器の壁厚（内径計算に使う）
    tol=0.15,           // はめ合い公差（大きいほど緩い）
    lid_h=6,            // フタの外側高さ（見える部分）
    insert_h=8,         // 容器内に差し込む深さ
    top_t=2.5,          // フタ天板の厚み
    mode="emboss",      // 上面テクスチャ：emboss/deboss/none
    top_tex="asanoha",  // 上面テクスチャ名（BOSL2名またはカスタム名）
    top_tex_size=[8,8],
    top_tex_depth=0.5,
    ring_border=0       // 外周縁取り（任意）
){
    // はめ合い寸法
    inner_d = d - 2*wall;               // 容器 内径（名目）
    insert_d = inner_d - tol;           // リップ外径（これが容器内に入る）
    body_d   = d;                       // フタ外輪の見える外径（必要に応じて +α）

    // 見える外輪
    color("SandyBrown")
    union(){
        // 外輪（側面）
        cylinder(h=lid_h, d=body_d);
        // 天板
        translate([0,0,lid_h - top_t])
            cylinder(h=top_t, d=body_d);

        // 上面テクスチャ
        if (mode != "none"){
            translate([0,0,lid_h])  // 天板の上に載せる/彫る
                top_textured_disk(
                    d=body_d, t=top_t,
                    mode=mode,
                    tex=top_tex,
                    tex_size=top_tex_size,
                    tex_depth=top_tex_depth,
                    keep_center=0,
                    ring_border=ring_border
                );
        }
    }

    // 差し込みリップ（容器内側へ）
    translate([0,0,0])
        difference(){
            cylinder(h=insert_h, d=insert_d);
            // 肉抜きして軽量化（任意）
            translate([0,0,0.6]) cylinder(h=insert_h, d=max(0, insert_d - 2.2));
        }
}

// ===========================================================
// Textured Press-Fit Lid (side texture + real press-fit plug)
// ===========================================================
module pressfit_lid_textured(
    // --- mating with container ---
    d=40,                 // container 外径（容器と同じ値）
    wall=1.6,             // container 壁厚
    tol=0.15,             // はめ合い（容器内径に対し これだけ小さく作る）
    // --- visible lid body (skirt) ---
    lid_h=6,              // 容器上に見える高さ
    body_offset=0,        // 見た目で外径を容器外径より少し大きくしたい時（0〜1mm程度）
    // --- side pattern on skirt ---
    side_mode="emboss",   // "emboss" / "deboss"
    side_tex="hex_grid",  // 側面模様（BOSL2名 or カスタム名）
    side_tex_size=[8,8],
    side_tex_depth=0.6,
    side_twist=0,
    side_grad_twist=0,
    side_pad_top=0,
    side_pad_bottom=0,
    side_border=0.0,
    // --- top (cap) plate + top texture (optional) ---
    top_t=2.5,
    top_mode="none",      // "emboss" / "deboss" / "none"
    top_tex="seigaiha",
    top_tex_size=[6,6],
    top_tex_depth=0.45,
    top_ring_border=0.0,
    // --- press-fit plug (insert) ---
    insert_h=8,           // 差し込み深さ（容器内に入る長さ）
    insert_wall_clear=2.2,// リップ中空化の肉厚（軽量化, 0で無効）
    // --- optional edge safety ---
    top_chamfer=0         // 見た目用：天板外周の面取り高さ（0=なし）
){
    // 寸法計算
    inner_d = d - 2*wall;           // 容器内径（名目）
    plug_d  = inner_d - tol;        // 差し込みリップ外径（公差で少し小さく）
    body_d  = d + body_offset;      // 見えるスカートの外径（意匠上の調整）

    // --- Lid visible body (skirt) with side texture ---
    union(){
        // 側面スカート：容器の外周と見た目で連続させたい場合は body_offset=0 を推奨
        side_textured_cylinder(
            d=body_d,
            h=lid_h,
            emboss_mode=side_mode,
            tex=side_tex,
            tex_size=side_tex_size,
            tex_depth=side_tex_depth,
            twist=side_twist,
            grad_twist=side_grad_twist,
            pad_top=side_pad_top,
            pad_bottom=side_pad_bottom,
            border=side_border
        );

        // 天板（上面テクスチャは天板上に加算/減算）
        translate([0,0,lid_h - top_t]){
            // ベース天板
            cylinder(h=top_t, d=body_d);
            // オプション：外周の簡易面取り
            if (top_chamfer>0){
                difference(){
                    translate([0,0,top_t-top_chamfer])
                        cylinder(h=top_chamfer, d=body_d);
                    translate([0,0,top_t-top_chamfer])
                        cylinder(h=top_chamfer, d1=body_d-2*top_chamfer, d2=body_d);
                }
            }
            // 上面模様
            if (top_mode!="none"){
                translate([0,0,top_t])    // 天板上面に重畳
                    top_textured_disk(
                        d=body_d, t=top_t,
                        mode=top_mode,
                        tex=top_tex,
                        tex_size=top_tex_size,
                        tex_depth=top_tex_depth,
                        keep_center=0,
                        ring_border=top_ring_border
                    );
            }
        }

        // 差し込みリップ（ここが「押し込み式」の要）
        // 容器の内壁に干渉しないよう、plug_d = inner_d - tol
        translate([0,0,0]){
            difference(){
                cylinder(h=insert_h, d=plug_d);
                if (insert_wall_clear>0)
                    translate([0,0,0.6])
                        cylinder(h=insert_h, d=max(0, plug_d - insert_wall_clear));
            }
        }
    }
}

module _linear_sweep_bosl2_named(d, h, tex, tex_size, tex_depth, twist, border){
    if (_border_ok(border)){
        linear_sweep(
            circle(d=d),
            texture=texture(tex, border=_border_safe(border)),
            tex_size=tex_size, tex_depth=tex_depth, h=h, twist=twist
        );
    } else {
        linear_sweep(
            circle(d=d),
            texture=texture(tex),
            tex_size=tex_size, tex_depth=tex_depth, h=h, twist=twist
        );
    }
}
