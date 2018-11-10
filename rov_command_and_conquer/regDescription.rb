# Bit index Description
@registers = {
:statusBits => [
 "system running (CSC OK)",
 "relay1 feedback (0-closed, 1-open)",
 "relay2 feedback (0-closed, 1-open)",
 "relay3 feedback (0-closed, 1-open)",
 "relay4 feedback (0-closed, 1-open)",
 "power switch 1 (0-open, 1-closed)",
 "power switch 2 (0-open, 1-closed)",
 "clamp enable (0-disabled, 1-enabled)",
 "OVP1 trigger",
 "OVP2 trigger",
 "UVP trigger",
 "OCP1 trigger",
 "OCP 2 trigger",
 "OCP negative trigger",
 "Zener input to_s_n",
 "Zener input to_fn_n",
 "Zener input OVL_Iz_n",
 "Safetylink1_n inhibit (also program inhibit for most,EEProm parameter like IP, OVP, OCP etc. *Active low, inhibit means FETS and relays are forced OFF )",
 "Unused",
 "UVP_delay_Trig",
 "OTP_trig",
 "Data_buffer_ready",
 "Data_buffer_overrun",
 "CRC_error"
],

:safetyLink_mask => [
"OVP1",
"OVP2",
"UVP",
"OCP1",
"OCP2",
"OCP negative",
"Local",
"External latched trigger or any trigger output is active in the other saftylink",
"UVP delayed trig of relay",
],


}



