from verif.tb.golden_model import SchedulerGoldenModel


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
