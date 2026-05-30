# Verdict — cand-ubo (beneficial-ownership look-through + indirect aggregation)

anchor-id: cand-ubo
class: candidate / natural
prompt-shasum: 61390635ece214c080b47385113df4fdfdb10b1b167ac9cc93ba27519ce4e7e0
check: checks/cand-ubo.check (require clause: ubo-aggregate)
n: 5
per-run: PASS PASS PASS PASS PASS
raw-outputs: runs/cand-ubo-1.txt … runs/cand-ubo-5.txt

verdict: DEGENERATE

This was the candidate with the best a-priori shot at headroom (the subtle multiply-and-sum of Anna Kovac's two indirect paths to 60%). All 5 runs nonetheless aggregate the paths correctly (30% + 30% = 60%, Boris 40%), apply the 25% threshold to natural persons, AND explicitly flag the single-path-undercount trap — unprompted. Zero headroom.
