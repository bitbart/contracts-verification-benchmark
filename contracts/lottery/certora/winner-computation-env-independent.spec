// SPDX-License-Identifier: GPL-3.0-only

// Given the same inputs, the fair win function yields the same output regardless of the environment

rule winner_computation_env_independent {
    env e1;
    env e2;

    address p0;
    address p1;
    require p0 != p1;
    string s0;
    string s1;

    address w1 = compute_winner(e1, p0, p1, s0, s1);
    address w2 = compute_winner(e2, p0, p1, s0, s1);

    assert w1 == w2;
}
