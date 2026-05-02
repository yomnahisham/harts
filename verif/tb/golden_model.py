def rtl_pq_key_priority(priority: int) -> int:
    """Matches control_unit sched_mode==2'b00: {12'b0, priority}."""
    return priority & 0xFFFF


def rtl_pq_key_rm(period: int) -> int:
    """Matches control_unit sched_mode==RM: ~period (16-bit)."""
    return (~period) & 0xFFFF


def rtl_pq_key_edf(tick: int, relative_deadline: int) -> int:
    """Matches control_unit sched_mode==EDF: ~(tick[15:0] + deadline)."""
    s = (tick + relative_deadline) & 0xFFFF
    return (~s) & 0xFFFF


class SchedulerGoldenModel:
    MODE_PRIORITY = 0
    MODE_RM = 1
    MODE_EDF = 2

    def __init__(self):
        self.mode = self.MODE_PRIORITY
        self.ready = []

    def key(self, task):
        if self.mode == self.MODE_PRIORITY:
            return task["priority"]
        if self.mode == self.MODE_RM:
            return -task["period"]
        return -task["deadline_abs"]

    def insert_ready(self, task):
        self.ready.append(task)
        self.ready.sort(key=self.key, reverse=True)

    def pop_next(self):
        if not self.ready:
            return None
        return self.ready.pop(0)
