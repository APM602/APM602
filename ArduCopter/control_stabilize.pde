/// -*- tab-width: 4; Mode: C++; c-basic-offset: 4; indent-tabs-mode: nil -*-

/*
 * control_stabilize.pde - init and run calls for stabilize flight mode
 */

// stabilize_init - initialise stabilize controller
static bool stabilize_init(bool ignore_checks)
{
    // set target altitude to zero for reporting
    // To-Do: make pos controller aware when it's active/inactive so it can always report the altitude error?
    pos_control.set_alt_target(0);

    // stabilize should never be made to fail
    return true;
}

// stabilize_run - runs the main stabilize controller
// should be called at 100hz or more
static void stabilize_run()//将用户输入转化为此时飞行模式下的倾斜角、滚转速率、爬升率等
{
    float target_roll, target_pitch;//目标滚转角俯仰角
    float target_yaw_rate;//目标偏航角速率
    int16_t pilot_throttle_scaled;

    // if not armed or throttle at zero, set throttle to zero and exit immediately如果没有启动或者油门为0，把油门设为0并立即退出
    if(!motors.armed() || g.rc_3.control_in <= 0) {
        attitude_control.relax_bf_rate_controller();
        attitude_control.set_yaw_target_to_current_heading();//把目标偏航设为当前方向
        attitude_control.set_throttle_out(0, false);//油门设为0
        return;
    }

    // apply SIMPLE mode transform to pilot inputs
    update_simple_mode();//跳至arducopter.pde

    // convert pilot input to lean angles
    // To-Do: convert get_pilot_desired_lean_angles to return angles as floats
    get_pilot_desired_lean_angles(g.rc_1.control_in, g.rc_2.control_in, target_roll, target_pitch);

    // get pilot's desired yaw rate
    target_yaw_rate = get_pilot_desired_yaw_rate(g.rc_4.control_in);

    // get pilot's desired throttle3为油门杆
    pilot_throttle_scaled = get_pilot_desired_throttle(g.rc_3.control_in);

    // call attitude controller地面坐标系下的滚转和俯仰角度及地面坐标系偏航速率，来稳定滚转角及俯仰角。
    attitude_control.angle_ef_roll_pitch_rate_ef_yaw_smooth(target_roll, target_pitch, target_yaw_rate, get_smoothing_gain());

    // body-frame rate controller is run directly from 100hz loop

    // output pilot's throttle
    attitude_control.set_throttle_out(pilot_throttle_scaled, true);
}
