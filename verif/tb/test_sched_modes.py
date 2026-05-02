"""Golden checks for PQ sort keys (mirror rtl/control_unit.v pq_enq_key)."""

from golden_model import (
    SchedulerGoldenModel,
    rtl_pq_key_edf,
    rtl_pq_key_rm,
    rtl_pq_key_priority,
)


def test_rm_key_orders_shorter_period_ahead():
    t0 = {"id": 0, "priority": 5, "period": 100, "deadline_abs": 0}
    t1 = {"id": 1, "priority": 5, "period": 20, "deadline_abs": 0}
    k0 = rtl_pq_key_rm(t0["period"])
    k1 = rtl_pq_key_rm(t1["period"])
    assert k1 > k0, "shorter period must yield larger RM key (higher-key wins in PQ)"


def test_edf_key_orders_tighter_deadline_at_tick_zero():
    k_loose = rtl_pq_key_edf(0, 200)
    k_tight = rtl_pq_key_edf(0, 20)
    assert k_tight > k_loose


def test_golden_rm_matches_rtl_keys():
    gm = SchedulerGoldenModel()
    gm.mode = SchedulerGoldenModel.MODE_RM
    gm.insert_ready({"id": 0, "priority": 1, "period": 100, "deadline_abs": 0})
    gm.insert_ready({"id": 1, "priority": 1, "period": 20, "deadline_abs": 0})
    assert gm.pop_next()["id"] == 1


def test_priority_key_monotonic():
    assert rtl_pq_key_priority(9) > rtl_pq_key_priority(3)
