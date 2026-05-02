from golden_model import SchedulerGoldenModel


def test_priority_sort():
    gm = SchedulerGoldenModel()
    gm.mode = SchedulerGoldenModel.MODE_PRIORITY
    gm.insert_ready({"id": 1, "priority": 2, "period": 10, "deadline_abs": 100})
    gm.insert_ready({"id": 2, "priority": 9, "period": 20, "deadline_abs": 200})
    assert gm.pop_next()["id"] == 2


def test_rm_sort():
    gm = SchedulerGoldenModel()
    gm.mode = SchedulerGoldenModel.MODE_RM
    gm.insert_ready({"id": 1, "priority": 1, "period": 50, "deadline_abs": 100})
    gm.insert_ready({"id": 2, "priority": 1, "period": 10, "deadline_abs": 100})
    assert gm.pop_next()["id"] == 2


def test_edf_sort_earlier_deadline_first():
    """MODE_EDF uses key = -deadline_abs (reverse sort → smaller deadline first)."""
    gm = SchedulerGoldenModel()
    gm.mode = SchedulerGoldenModel.MODE_EDF
    gm.insert_ready({"id": 1, "priority": 1, "period": 10, "deadline_abs": 500})
    gm.insert_ready({"id": 2, "priority": 1, "period": 10, "deadline_abs": 50})
    assert gm.pop_next()["id"] == 2


def test_pop_next_empty_returns_none():
    gm = SchedulerGoldenModel()
    assert gm.pop_next() is None
    gm.insert_ready({"id": 0, "priority": 1, "period": 1, "deadline_abs": 1})
    assert gm.pop_next()["id"] == 0
    assert gm.pop_next() is None
