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
