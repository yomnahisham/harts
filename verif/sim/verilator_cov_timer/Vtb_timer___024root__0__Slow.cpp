// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_timer.h for the primary calling header

#include "Vtb_timer__pch.h"

void Vtb_timer___024root___timing_ready(Vtb_timer___024root* vlSelf);

VL_ATTR_COLD void Vtb_timer___024root___eval_static(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval_static\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_timer__DOT__clk = 0U;
    ++(vlSymsp->__Vcoverage[0]);
    vlSelfRef.tb_timer__DOT__rst_n = 0U;
    ++(vlSymsp->__Vcoverage[1]);
    vlSelfRef.tb_timer__DOT__enable = 0U;
    ++(vlSymsp->__Vcoverage[2]);
    vlSelfRef.tb_timer__DOT__tick_divider = 2U;
    ++(vlSymsp->__Vcoverage[3]);
    vlSelfRef.__Vtrigprevexpr___TOP__tb_timer__DOT__clk__0 = 0U;
    vlSelfRef.__Vtrigprevexpr___TOP__tb_timer__DOT__rst_n__0 = 0U;
    Vtb_timer___024root___timing_ready(vlSelf);
    do {
        vlSelfRef.__VactTriggeredAcc[vlSelfRef.__Vi] 
            = vlSelfRef.__VactTriggered[vlSelfRef.__Vi];
        vlSelfRef.__Vi = ((IData)(1U) + vlSelfRef.__Vi);
    } while ((0U >= vlSelfRef.__Vi));
}

VL_ATTR_COLD void Vtb_timer___024root___eval_static__TOP(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval_static__TOP\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_timer__DOT__clk = 0U;
    ++(vlSymsp->__Vcoverage[0]);
    vlSelfRef.tb_timer__DOT__rst_n = 0U;
    ++(vlSymsp->__Vcoverage[1]);
    vlSelfRef.tb_timer__DOT__enable = 0U;
    ++(vlSymsp->__Vcoverage[2]);
    vlSelfRef.tb_timer__DOT__tick_divider = 2U;
    ++(vlSymsp->__Vcoverage[3]);
}

VL_ATTR_COLD void Vtb_timer___024root___eval_final(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval_final\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vtb_timer___024root___eval_settle(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval_settle\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

bool Vtb_timer___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_timer___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(Vtb_timer___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge tb_timer.clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @(negedge tb_timer.rst_n)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 2U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_timer___024root___ctor_var_reset(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___ctor_var_reset\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->tb_timer__DOT__tick_pulse = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2962778092689222074ull);
    vlSelf->tb_timer__DOT__tick_counter = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 3096535388980159566ull);
    vlSelf->__Vdly__tb_timer__DOT__tick_counter = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggeredAcc[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__tb_timer__DOT__clk__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__tb_timer__DOT__rst_n__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
    vlSelf->__Vi = 0;
}

VL_ATTR_COLD void Vtb_timer___024root___configure_coverage(Vtb_timer___024root* vlSelf, bool first) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___configure_coverage\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    (void)first;  // Prevent unused variable warning
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[0]), first, "verif/tb_verilog/tb_timer.v", 3, 15, ".tb_timer", "v_line/tb_timer", "block", "3");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[1]), first, "verif/tb_verilog/tb_timer.v", 4, 17, ".tb_timer", "v_line/tb_timer", "block", "4");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[2]), first, "verif/tb_verilog/tb_timer.v", 5, 18, ".tb_timer", "v_line/tb_timer", "block", "5");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[3]), first, "verif/tb_verilog/tb_timer.v", 6, 31, ".tb_timer", "v_line/tb_timer", "block", "6");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[4]), first, "verif/tb_verilog/tb_timer.v", 20, 5, ".tb_timer", "v_line/tb_timer", "block", "20");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[5]), first, "verif/tb_verilog/tb_timer.v", 24, 13, ".tb_timer", "v_branch/tb_timer", "if", "24-26");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[6]), first, "verif/tb_verilog/tb_timer.v", 24, 14, ".tb_timer", "v_branch/tb_timer", "else", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[7]), first, "verif/tb_verilog/tb_timer.v", 28, 13, ".tb_timer", "v_branch/tb_timer", "if", "28-30");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[8]), first, "verif/tb_verilog/tb_timer.v", 28, 14, ".tb_timer", "v_branch/tb_timer", "else", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[9]), first, "verif/tb_verilog/tb_timer.v", 23, 9, ".tb_timer", "v_branch/tb_timer", "if", "23");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[10]), first, "verif/tb_verilog/tb_timer.v", 23, 10, ".tb_timer", "v_branch/tb_timer", "else", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[11]), first, "verif/tb_verilog/tb_timer.v", 22, 5, ".tb_timer", "v_line/tb_timer", "block", "22");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[12]), first, "verif/tb_verilog/tb_timer.v", 37, 9, ".tb_timer", "v_line/tb_timer", "block", "37");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[13]), first, "verif/tb_verilog/tb_timer.v", 42, 13, ".tb_timer", "v_branch/tb_timer", "if", "42");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[14]), first, "verif/tb_verilog/tb_timer.v", 42, 14, ".tb_timer", "v_branch/tb_timer", "else", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[15]), first, "verif/tb_verilog/tb_timer.v", 40, 9, ".tb_timer", "v_line/tb_timer", "block", "40-41");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[16]), first, "verif/tb_verilog/tb_timer.v", 44, 9, ".tb_timer", "v_branch/tb_timer", "if", "44-46");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[17]), first, "verif/tb_verilog/tb_timer.v", 44, 10, ".tb_timer", "v_branch/tb_timer", "else", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[18]), first, "verif/tb_verilog/tb_timer.v", 35, 5, ".tb_timer", "v_line/tb_timer", "block", "35-40,48-49");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[19]), first, "rtl/timer.v", 17, 13, ".tb_timer.dut", "v_branch/timer", "if", "17-19");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[20]), first, "rtl/timer.v", 17, 14, ".tb_timer.dut", "v_branch/timer", "else", "20-22");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[21]), first, "rtl/timer.v", 13, 18, ".tb_timer.dut", "v_line/timer", "if", "13-15");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[22]), first, "rtl/timer.v", 13, 19, ".tb_timer.dut", "v_line/timer", "else", "16");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[23]), first, "rtl/timer.v", 10, 9, ".tb_timer.dut", "v_line/timer", "elsif", "10-12");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[24]), first, "rtl/timer.v", 9, 5, ".tb_timer.dut", "v_line/timer", "block", "9");
}
