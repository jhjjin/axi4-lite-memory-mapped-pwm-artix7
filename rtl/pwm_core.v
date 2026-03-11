`timescale 1ns / 1ps

module pwm_core(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [31:0] period,
    input wire [31:0] duty,
    output reg pwm_out,
    output reg done
);

reg [31:0] counter;
reg [31:0] duty_sat;

// next counter logic
wire [31:0] counter_next;
assign counter_next = (counter == period - 1) ? 0 : counter + 1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter  <= 0;
        duty_sat <= 0;
        pwm_out  <= 0;
        done     <= 0;
    end
    else begin

        // default done
        done <= 0;

        // duty saturation
        if (duty > period)
            duty_sat <= period;
        else
            duty_sat <= duty;

        // disable or invalid period
        if (!enable || period == 0) begin
            counter <= 0;
            pwm_out <= 0;
        end
        else begin
            counter <= counter_next;

            // done when one cycle finishes
            if (counter == period - 1)
                done <= 1;

            // compare using next counter
            pwm_out <= (counter_next < duty_sat);
        end
    end
end

endmodule