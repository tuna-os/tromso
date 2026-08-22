import unittest

from scripts.report_multirunner_timings import build_profile


def job(name, start, end, conclusion="success"):
    return {
        "name": name,
        "started_at": f"2026-08-10T00:{start:02d}:00Z",
        "completed_at": f"2026-08-10T00:{end:02d}:00Z",
        "conclusion": conclusion,
    }


class ReportMultiRunnerTimingsTest(unittest.TestCase):
    def test_ignores_failed_jobs_and_requires_minimum_samples(self):
        runs = [
            {"id": 2, "status": "completed"},
            {"id": 1, "status": "completed"},
        ]
        jobs = {
            "1": [job("multirunner / Build chunk0-a", 0, 10)],
            "2": [job("multirunner / Build chunk0-a", 0, 20), job("multirunner / Build chunk1-b", 0, 5, "failure")],
        }

        profile = build_profile(runs, jobs, min_samples=3)

        self.assertFalse(profile["ready_for_weighted_planner"])
        self.assertEqual(profile["summary"]["chunk0-a"]["samples"], 2)
        self.assertNotIn("chunk1-b", profile["summary"])
        self.assertEqual(profile["summary"]["chunk0-a"]["median_seconds"], 900.0)

    def test_reports_ready_when_all_observed_chunks_have_enough_samples(self):
        runs = [{"id": 1, "status": "completed"}]
        jobs = {
            "1": [
                job("multirunner / Build chunk0-a", 0, 10),
                job("multirunner / Build chunk0-a", 10, 20),
                job("multirunner / Build chunk1-b", 0, 30),
                job("multirunner / Build chunk1-b", 30, 59),
            ]
        }

        profile = build_profile(runs, jobs, min_samples=2)

        self.assertTrue(profile["ready_for_weighted_planner"])
        self.assertEqual(profile["source_runs"], [1])


if __name__ == "__main__":
    unittest.main()
