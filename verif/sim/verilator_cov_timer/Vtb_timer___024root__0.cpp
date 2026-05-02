// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_timer.h for the primary calling header

#include "Vtb_timer__pch.h"

VlCoroutine Vtb_timer___024root___eval_initial__TOP__Vtiming__0(Vtb_timer___024root* vlSelf);
VlCoroutine Vtb_timer___024root___eval_initial__TOP__Vtiming__1(Vtb_timer___024root* vlSelf);

void Vtb_timer___024root___eval_initial(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval_initial\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vtb_timer___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vtb_timer___024root___eval_initial__TOP__Vtiming__1(vlSelf);
}

void Vtb_timer___024root____VbeforeTrig_hef8976d8__0(Vtb_timer___024root* vlSelf, const char* __VeventDescription);

VlCoroutine Vtb_timer___024root___eval_initial__TOP__Vtiming__0(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval_initial__TOP__Vtiming__0\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ tb_timer__DOT__pulses;
    tb_timer__DOT__pulses = 0;
    IData/*31:0*/ tb_timer__DOT__unnamedblk1_1__DOT____Vrepeat0;
    tb_timer__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0;
    IData/*31:0*/ tb_timer__DOT__unnamedblk1_2__DOT____Vrepeat1;
    tb_timer__DOT__unnamedblk1_2__DOT____Vrepeat1 = 0;
    // Body
    tb_timer__DOT__pulses = 0U;
    tb_timer__DOT__unnamedblk1_1__DOT____Vrepeat0 = 3U;
    while (VL_LTS_III(32, 0U, tb_timer__DOT__unnamedblk1_1__DOT____Vrepeat0)) {
        Vtb_timer___024root____VbeforeTrig_hef8976d8__0(vlSelf, 
                                                        "@(posedge tb_timer.clk)");
        co_await vlSelfRef.__VtrigSched_hef8976d8__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge tb_timer.clk)", 
                                                             "verif/tb_verilog/tb_timer.v", 
                                                             37);
        tb_timer__DOT__unnamedblk1_1__DOT____Vrepeat0 
            = (tb_timer__DOT__unnamedblk1_1__DOT____Vrepeat0 
               - (IData)(1U));
        ++(vlSymsp->__Vcoverage[12]);
    }
    vlSelfRef.tb_timer__DOT__rst_n = 1U;
    vlSelfRef.tb_timer__DOT__enable = 1U;
    tb_timer__DOT__unnamedblk1_2__DOT____Vrepeat1 = 0x00000014U;
    while (VL_LTS_III(32, 0U, tb_timer__DOT__unnamedblk1_2__DOT____Vrepeat1)) {
        Vtb_timer___024root____VbeforeTrig_hef8976d8__0(vlSelf, 
                                                        "@(posedge tb_timer.clk)");
        co_await vlSelfRef.__VtrigSched_hef8976d8__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge tb_timer.clk)", 
                                                             "verif/tb_verilog/tb_timer.v", 
                                                             41);
        if (vlSelfRef.tb_timer__DOT__tick_pulse) {
            tb_timer__DOT__pulses = ((IData)(1U) + tb_timer__DOT__pulses);
            ++(vlSymsp->__Vcoverage[13]);
        } else {
            ++(vlSymsp->__Vcoverage[14]);
        }
        tb_timer__DOT__unnamedblk1_2__DOT____Vrepeat1 
            = (tb_timer__DOT__unnamedblk1_2__DOT____Vrepeat1 
               - (IData)(1U));
        ++(vlSymsp->__Vcoverage[15]);
    }
    if (VL_UNLIKELY((VL_GTS_III(32, 4U, tb_timer__DOT__pulses)))) {
        VL_WRITEF_NX("fail not enough pulses\n",0);
        VL_FINISH_MT("verif/tb_verilog/tb_timer.v", 46, "");
        ++(vlSymsp->__Vcoverage[16]);
    } else {
        ++(vlSymsp->__Vcoverage[17]);
    }
    VL_WRITEF_NX("pass\n",0);
    VL_FINISH_MT("verif/tb_verilog/tb_timer.v", 49, "");
    ++(vlSymsp->__Vcoverage[18]);
    co_return;
}

VlCoroutine Vtb_timer___024root___eval_initial__TOP__Vtiming__1(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval_initial__TOP__Vtiming__1\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    while (VL_LIKELY(!vlSymsp->_vm_contextp__->gotFinish())) {
        co_await vlSelfRef.__VdlySched.delay(0x0000000000001388ULL, 
                                             nullptr, 
                                             "verif/tb_verilog/tb_timer.v", 
                                             20);
        vlSelfRef.tb_timer__DOT__clk = (1U & (~ (IData)(vlSelfRef.tb_timer__DOT__clk)));
        ++(vlSymsp->__Vcoverage[4]);
    }
    co_return;
}

void Vtb_timer___024root___eval_triggers_vec__act(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval_triggers_vec__act\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                    ((vlSelfRef.__VdlySched.awaitingCurrentTime() 
                                                      << 2U) 
                                                     | ((((~ (IData)(vlSelfRef.tb_timer__DOT__rst_n)) 
                                                          & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_timer__DOT__rst_n__0)) 
                                                         << 1U) 
                                                        | ((IData)(vlSelfRef.tb_timer__DOT__clk) 
                                                           & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_timer__DOT__clk__0)))))));
    vlSelfRef.__Vtrigprevexpr___TOP__tb_timer__DOT__clk__0 
        = vlSelfRef.tb_timer__DOT__clk;
    vlSelfRef.__Vtrigprevexpr___TOP__tb_timer__DOT__rst_n__0 
        = vlSelfRef.tb_timer__DOT__rst_n;
}

bool Vtb_timer___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___trigger_anySet__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

void Vtb_timer___024root___nba_sequent__TOP__0(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___nba_sequent__TOP__0\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vdly__tb_timer__DOT__tick_counter = vlSelfRef.tb_timer__DOT__tick_counter;
}

void Vtb_timer___024root___nba_sequent__TOP__1(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___nba_sequent__TOP__1\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSelfRef.tb_timer__DOT__rst_n) {
        ++(vlSymsp->__Vcoverage[6]);
        if (VL_UNLIKELY((((IData)(vlSelfRef.tb_timer__DOT__tick_pulse) 
                          & ((IData)(vlSelfRef.tb_timer__DOT__tick_counter) 
                             != (IData)(vlSelfRef.tb_timer__DOT__tick_divider)))))) {
            VL_WRITEF_NX("fail timer reload mismatch\n",0);
            VL_FINISH_MT("verif/tb_verilog/tb_timer.v", 30, "");
            ++(vlSymsp->__Vcoverage[7]);
        } else {
            ++(vlSymsp->__Vcoverage[8]);
        }
        ++(vlSymsp->__Vcoverage[9]);
    } else {
        ++(vlSymsp->__Vcoverage[10]);
    }
    ++(vlSymsp->__Vcoverage[11]);
}

void Vtb_timer___024root___nba_sequent__TOP__2(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___nba_sequent__TOP__2\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (vlSelfRef.tb_timer__DOT__rst_n) {
        if (vlSelfRef.tb_timer__DOT__enable) {
            if ((0U == (IData)(vlSelfRef.tb_timer__DOT__tick_counter))) {
                ++(vlSymsp->__Vcoverage[19]);
                vlSelfRef.__Vdly__tb_timer__DOT__tick_counter 
                    = vlSelfRef.tb_timer__DOT__tick_divider;
                vlSelfRef.tb_timer__DOT__tick_pulse = 1U;
            } else {
                vlSelfRef.__Vdly__tb_timer__DOT__tick_counter 
                    = (0x0000ffffU & ((IData)(vlSelfRef.tb_timer__DOT__tick_counter) 
                                      - (IData)(1U)));
                ++(vlSymsp->__Vcoverage[20]);
                vlSelfRef.tb_timer__DOT__tick_pulse = 0U;
            }
            ++(vlSymsp->__Vcoverage[22]);
        } else {
            vlSelfRef.__Vdly__tb_timer__DOT__tick_counter 
                = vlSelfRef.tb_timer__DOT__tick_divider;
            ++(vlSymsp->__Vcoverage[21]);
            vlSelfRef.tb_timer__DOT__tick_pulse = 0U;
        }
    } else {
        vlSelfRef.__Vdly__tb_timer__DOT__tick_counter = 0U;
        ++(vlSymsp->__Vcoverage[23]);
        vlSelfRef.tb_timer__DOT__tick_pulse = 0U;
    }
    ++(vlSymsp->__Vcoverage[24]);
    vlSelfRef.tb_timer__DOT__tick_counter = vlSelfRef.__Vdly__tb_timer__DOT__tick_counter;
}

void Vtb_timer___024root___eval_nba(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval_nba\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((3ULL & vlSelfRef.__VnbaTriggered[0U])) {
        vlSelfRef.__Vdly__tb_timer__DOT__tick_counter 
            = vlSelfRef.tb_timer__DOT__tick_counter;
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered[0U])) {
        if (vlSelfRef.tb_timer__DOT__rst_n) {
            ++(vlSymsp->__Vcoverage[6]);
            if (VL_UNLIKELY((((IData)(vlSelfRef.tb_timer__DOT__tick_pulse) 
                              & ((IData)(vlSelfRef.tb_timer__DOT__tick_counter) 
                                 != (IData)(vlSelfRef.tb_timer__DOT__tick_divider)))))) {
                VL_WRITEF_NX("fail timer reload mismatch\n",0);
                VL_FINISH_MT("verif/tb_verilog/tb_timer.v", 30, "");
                ++(vlSymsp->__Vcoverage[7]);
            } else {
                ++(vlSymsp->__Vcoverage[8]);
            }
            ++(vlSymsp->__Vcoverage[9]);
        } else {
            ++(vlSymsp->__Vcoverage[10]);
        }
        ++(vlSymsp->__Vcoverage[11]);
    }
    if ((3ULL & vlSelfRef.__VnbaTriggered[0U])) {
        if (vlSelfRef.tb_timer__DOT__rst_n) {
            if (vlSelfRef.tb_timer__DOT__enable) {
                if ((0U == (IData)(vlSelfRef.tb_timer__DOT__tick_counter))) {
                    ++(vlSymsp->__Vcoverage[19]);
                    vlSelfRef.__Vdly__tb_timer__DOT__tick_counter 
                        = vlSelfRef.tb_timer__DOT__tick_divider;
                    vlSelfRef.tb_timer__DOT__tick_pulse = 1U;
                } else {
                    vlSelfRef.__Vdly__tb_timer__DOT__tick_counter 
                        = (0x0000ffffU & ((IData)(vlSelfRef.tb_timer__DOT__tick_counter) 
                                          - (IData)(1U)));
                    ++(vlSymsp->__Vcoverage[20]);
                    vlSelfRef.tb_timer__DOT__tick_pulse = 0U;
                }
                ++(vlSymsp->__Vcoverage[22]);
            } else {
                vlSelfRef.__Vdly__tb_timer__DOT__tick_counter 
                    = vlSelfRef.tb_timer__DOT__tick_divider;
                ++(vlSymsp->__Vcoverage[21]);
                vlSelfRef.tb_timer__DOT__tick_pulse = 0U;
            }
        } else {
            vlSelfRef.__Vdly__tb_timer__DOT__tick_counter = 0U;
            ++(vlSymsp->__Vcoverage[23]);
            vlSelfRef.tb_timer__DOT__tick_pulse = 0U;
        }
        ++(vlSymsp->__Vcoverage[24]);
        vlSelfRef.tb_timer__DOT__tick_counter = vlSelfRef.__Vdly__tb_timer__DOT__tick_counter;
    }
}

void Vtb_timer___024root___timing_ready(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___timing_ready\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_hef8976d8__0.ready("@(posedge tb_timer.clk)");
    }
}

void Vtb_timer___024root___timing_resume(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___timing_resume\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VtrigSched_hef8976d8__0.moveToResumeQueue(
                                                          "@(posedge tb_timer.clk)");
    vlSelfRef.__VtrigSched_hef8976d8__0.resume("@(posedge tb_timer.clk)");
    if ((4ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Vtb_timer___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___trigger_orInto__act_vec_vec\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((0U >= n));
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_timer___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

bool Vtb_timer___024root___eval_phase__act(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval_phase__act\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VactExecute;
    // Body
    Vtb_timer___024root___eval_triggers_vec__act(vlSelf);
    Vtb_timer___024root___timing_ready(vlSelf);
    Vtb_timer___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VactTriggered, vlSelfRef.__VactTriggeredAcc);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_timer___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
    Vtb_timer___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    __VactExecute = Vtb_timer___024root___trigger_anySet__act(vlSelfRef.__VactTriggered);
    if (__VactExecute) {
        vlSelfRef.__VactTriggeredAcc.fill(0ULL);
        Vtb_timer___024root___timing_resume(vlSelf);
    }
    return (__VactExecute);
}

bool Vtb_timer___024root___eval_phase__inact(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval_phase__inact\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VinactExecute;
    // Body
    __VinactExecute = vlSelfRef.__VdlySched.awaitingZeroDelay();
    if (__VinactExecute) {
        VL_FATAL_MT("verif/tb_verilog/tb_timer.v", 2, "", "ZERODLY: Design Verilated with '--no-sched-zero-delay', but #0 delay executed at runtime");
    }
    return (__VinactExecute);
}

void Vtb_timer___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool Vtb_timer___024root___eval_phase__nba(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval_phase__nba\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vtb_timer___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        Vtb_timer___024root___eval_nba(vlSelf);
        Vtb_timer___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

void Vtb_timer___024root___eval(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VnbaIterCount;
    // Body
    __VnbaIterCount = 0U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vtb_timer___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
            VL_FATAL_MT("verif/tb_verilog/tb_timer.v", 2, "", "DIDNOTCONVERGE: NBA region did not converge after '--converge-limit' of 100 tries");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        vlSelfRef.__VinactIterCount = 0U;
        do {
            if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VinactIterCount)))) {
                VL_FATAL_MT("verif/tb_verilog/tb_timer.v", 2, "", "DIDNOTCONVERGE: Inactive region did not converge after '--converge-limit' of 100 tries");
            }
            vlSelfRef.__VinactIterCount = ((IData)(1U) 
                                           + vlSelfRef.__VinactIterCount);
            vlSelfRef.__VactIterCount = 0U;
            do {
                if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                    Vtb_timer___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
                    VL_FATAL_MT("verif/tb_verilog/tb_timer.v", 2, "", "DIDNOTCONVERGE: Active region did not converge after '--converge-limit' of 100 tries");
                }
                vlSelfRef.__VactIterCount = ((IData)(1U) 
                                             + vlSelfRef.__VactIterCount);
                vlSelfRef.__VactPhaseResult = Vtb_timer___024root___eval_phase__act(vlSelf);
            } while (vlSelfRef.__VactPhaseResult);
            vlSelfRef.__VinactPhaseResult = Vtb_timer___024root___eval_phase__inact(vlSelf);
        } while (vlSelfRef.__VinactPhaseResult);
        vlSelfRef.__VnbaPhaseResult = Vtb_timer___024root___eval_phase__nba(vlSelf);
    } while (vlSelfRef.__VnbaPhaseResult);
}

void Vtb_timer___024root____VbeforeTrig_hef8976d8__0(Vtb_timer___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root____VbeforeTrig_hef8976d8__0\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)(((IData)(vlSelfRef.tb_timer__DOT__clk) 
                                  & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_timer__DOT__clk__0)))));
    vlSelfRef.__Vtrigprevexpr___TOP__tb_timer__DOT__clk__0 
        = vlSelfRef.tb_timer__DOT__clk;
    if ((1ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_hef8976d8__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_hef8976d8__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

#ifdef VL_DEBUG
void Vtb_timer___024root___eval_debug_assertions(Vtb_timer___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_timer___024root___eval_debug_assertions\n"); );
    Vtb_timer__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
