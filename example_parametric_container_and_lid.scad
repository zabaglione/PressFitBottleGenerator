// example_parametric_container_and_lid.scad
// Parametric sample using texlib.scad (assumes patched border handling)
// Dependencies: BOSL2, texlib.scad
include <BOSL2/std.scad>
include <texlib.scad>

$fn = 180;

/* [What to Build] */
// 何を作るか
Build = "Both";                // [Both, Container_Only, Lid_Only]
// 配置：横並び or 積み重ね表示
Arrange = "SideBySide";        // [SideBySide, Stacked]
// モデル間の距離（SideBySide時の左右間隔／Stacked時の上下間隔）
Spacing = 35;                  // [10:5:120]

/* [Container - Basic] */
// 外径
D = 40;                        // [20:1:240]
// 高さ
H = 30;                        // [10:1:240]
// 壁厚
Wall = 1.6;                    // [0.8:0.1:5.0]
// 底厚
Bottom = 2.0;                  // [0.8:0.1:6.0]

/* [Container - Side Texture] */
// 模様モード（容器側面の凹凸）
Emboss_Mode = "emboss";        // [emboss, deboss]
/* [Container - Side Texture] */
// 模様名（BOSL2名 or カスタム名）をプルダウン選択できるように設定
Tex_Name = "hex_grid";  // [none, bricks, checkers, cones, cubes, diamonds, diamonds_vnf, hex_grid, hills, pyramids, ribs, rough, tri_grid, trunc_diamonds, trunc_pyramids_vnf, trunc_ribs, trunc_ribs_vnf, wave_ribs, asanoha, seigaiha, diagonal_ribs, polar_waves]
// タイルサイズ
Tex_Size_X = 8;                // [4:1:40]
Tex_Size_Y = 8;                // [4:1:40]
// 模様の深さ
Tex_Depth = 0.6;               // [0.1:0.05:2.0]
// 全体ツイスト
Twist = 0;                     // [0:1:45]
// 高さ方向の追加ツイスト（線形勾配）
Grad_Twist = 12;               // [0:1:60]
// 上下パディング（模様なし帯域）
Pad_Top = 0;                   // [0:1:20]
Pad_Bottom = 0;                // [0:1:20]
// 境界ボーダー（BOSL2の制約 0<border<0.5。0または0.5以上は無効扱い）
Border = 0.4;                  // [0:0.01:0.49]

/* [Lid - Fit & Structure] */
// 押し込み公差（大きいほど緩くなる）
Tol = 0.15;                    // [0.05:0.01:0.40]
// フタの見える側面高さ（スカート）
Lid_H = 6;                     // [3:1:20]
// 見た目で外径を大きくするオフセット（意匠）
Body_Offset = 0;               // [0:0.1:2.0]
// 容器内への差し込み深さ
Insert_H = 8;                  // [4:1:20]
// 差し込みリップの中空化厚み（0で無効）
Insert_Wall_Clear = 2.2;       // [0:0.1:4.0]

/* [Lid - Side Texture] */
// フタ側面を容器と同じ設定にする
Lid_Side_SameAs_Container = true;  // [true, false]
// ※ false の場合のみ以下を使用
Lid_Side_Mode = "emboss";      // [emboss, deboss]
Lid_Side_Tex = "hex_grid";
Lid_Side_Size_X = 8;           // [4:1:40]
Lid_Side_Size_Y = 8;           // [4:1:40]
Lid_Side_Depth = 0.6;          // [0.1:0.05:2.0]
Lid_Side_Twist = 0;            // [0:1:45]
Lid_Side_Grad_Twist = 12;      // [0:1:60]
Lid_Side_Pad_Top = 0;          // [0:1:20]
Lid_Side_Pad_Bottom = 0;       // [0:1:20]
Lid_Side_Border = 0.0;         // [0:0.01:0.49]

/* [Lid - Top Texture] */
// 天板厚
Top_T = 2.5;                   // [1.0:0.1:6.0]
// 上面模様モード
Top_Mode = "none";             // [none, emboss, deboss]
// 上面模様名
Top_Tex = "seigaiha";
// 上面タイルサイズ
Top_Size_X = 6;                // [4:1:40]
Top_Size_Y = 6;                // [4:1:40]
// 上面模様深さ
Top_Depth = 0.45;              // [0.1:0.05:2.0]
// 外周の縁取り幅
Top_Ring_Border = 1.0;         // [0:0.1:3.0]
// 天板外周の面取り高さ
Top_Chamfer = 0;               // [0:0.1:2.0]

// -----------------------------
// 容器・フタの描画
// -----------------------------
module _draw_container(){
    textured_container(
        d=D, h=H, wall=Wall, bottom=Bottom,
        emboss_mode=Emboss_Mode,
        tex=Tex_Name, tex_size=[Tex_Size_X, Tex_Size_Y], tex_depth=Tex_Depth,
        twist=Twist, grad_twist=Grad_Twist,
        pad_top=Pad_Top, pad_bottom=Pad_Bottom,
        border=Border
    );
}

module _draw_lid(){
    // フタ側面パターンの実引数決定
    _smode = Lid_Side_SameAs_Container ? Emboss_Mode : Lid_Side_Mode;
    _stex  = Lid_Side_SameAs_Container ? Tex_Name    : Lid_Side_Tex;
    _ssize = Lid_Side_SameAs_Container ? [Tex_Size_X, Tex_Size_Y] : [Lid_Side_Size_X, Lid_Side_Size_Y];
    _sdep  = Lid_Side_SameAs_Container ? Tex_Depth   : Lid_Side_Depth;
    _stwist= Lid_Side_SameAs_Container ? Twist       : Lid_Side_Twist;
    _sgtw  = Lid_Side_SameAs_Container ? Grad_Twist  : Lid_Side_Grad_Twist;
    _spadt = Lid_Side_SameAs_Container ? Pad_Top     : Lid_Side_Pad_Top;
    _spadb = Lid_Side_SameAs_Container ? Pad_Bottom  : Lid_Side_Pad_Bottom;
    _sbrdr = Lid_Side_SameAs_Container ? Border      : Lid_Side_Border;

    pressfit_lid_textured(
        d=D, wall=Wall, tol=Tol,
        lid_h=Lid_H, body_offset=Body_Offset,
        side_mode=_smode,
        side_tex=_stex, side_tex_size=_ssize, side_tex_depth=_sdep,
        side_twist=_stwist, side_grad_twist=_sgtw,
        side_pad_top=_spadt, side_pad_bottom=_spadb,
        side_border=_sbrdr,
        top_t=Top_T, top_mode=Top_Mode,
        top_tex=Top_Tex, top_tex_size=[Top_Size_X, Top_Size_Y], top_tex_depth=Top_Depth,
        top_ring_border=Top_Ring_Border, top_chamfer=Top_Chamfer,
        insert_h=Insert_H, insert_wall_clear=Insert_Wall_Clear
    );
}

// 配置ユーティリティ
module _place_container(){
    if (Arrange=="SideBySide") translate([-Spacing,0,0]) _draw_container();
    else                       translate([0,0,0])        _draw_container();
}
module _place_lid(){
    if (Arrange=="SideBySide") translate([+Spacing,0,0]) _draw_lid();
    else                       translate([0,0,H + Top_T + 1]) _draw_lid();
}

// ルート分岐
if (Build=="Both"){
    _place_container();
    _place_lid();
} else if (Build=="Container_Only"){
    _place_container();
} else if (Build=="Lid_Only"){
    _place_lid();
}
