// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb_timer.h for the primary calling header

#ifndef VERILATED_VTB_TIMER___024ROOT_H_
#define VERILATED_VTB_TIMER___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_cov.h"
#include "verilated_timing.h"


class Vtb_timer__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtb_timer___024root final {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ tb_timer__DOT__clk;
    CData/*0:0*/ tb_timer__DOT__rst_n;
    CData/*0:0*/ tb_timer__DOT__enable;
    CData/*0:0*/ tb_timer__DOT__tick_pulse;
    CData/*0:0*/ __Vtrigprevexpr___TOP__tb_timer__DOT__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__tb_timer__DOT__rst_n__0;
    CData/*0:0*/ __VactPhaseResult;
    CData/*0:0*/ __VinactPhaseResult;
    CData/*0:0*/ __VnbaPhaseResult;
    SData/*15:0*/ tb_timer__DOT__tick_divider;
    SData/*15:0*/ tb_timer__DOT__tick_counter;
    SData/*15:0*/ __Vdly__tb_timer__DOT__tick_counter;
    IData/*31:0*/ __VactIterCount;
    IData/*31:0*/ __VinactIterCount;
    IData/*31:0*/ __Vi;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggeredAcc;
    VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_hef8976d8__0;

    // INTERNAL VARIABLES
    Vtb_timer__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vtb_timer___024root(Vtb_timer__Syms* symsp, const char* namep);
    ~Vtb_timer___024root();
    VL_UNCOPYABLE(Vtb_timer___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
    void __vlCoverInsert(uint32_t* countp, bool enable, const char* filenamep, int lineno, int column,
        const char* hierp, const char* pagep, const char* commentp, const char* linescovp);
};


#endif  // guard
