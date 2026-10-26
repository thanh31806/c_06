`timescale 1ns/1ps

module tb;
    // Khai báo tín hiệu kết nối với DUT (theo chuẩn Tiny Tapeout)
    logic clk;
    logic rst_n;
    logic ena;
    logic [7:0] ui_in;
    logic [7:0] uio_in;
    wire  [7:0] uo_out;
    wire  [7:0] uio_out;
    wire  [7:0] uio_oe;

    // Khởi tạo module (Tên module phải khớp với file project.v)
    tt_um_c06_core dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Tạo xung clock chu kỳ 10ns
    always #5 clk = ~clk;

    // Task nạp một mẫu dữ liệu
    task automatic apply_cycle(input [7:0] sample, input [7:0] thresh);
        begin
            ui_in = sample;
            uio_in = thresh;
            @(posedge clk);
            #1;
        end
    endtask

    // Task reset mạch
    task automatic reset_dut;
        begin
            rst_n = 0;
            ui_in = 0;
            uio_in = 0;
            repeat(2) @(posedge clk);
            rst_n = 1;
            #1;
        end
    endtask

    initial begin
        // Khởi tạo
        clk = 0;
        rst_n = 1;
        ena = 1; // Enable = 1 để mạch hoạt động
        ui_in = 0;
        uio_in = 0;

        // =====================================================================
        // CA KIỂM THỬ 1: Sự kiện tại chu kỳ 1, 255, 256 (Kỳ vọng: 3)
        // =====================================================================
        reset_dut();
        apply_cycle(8'd101, 8'd100); // Chu kỳ 1
        for (int i=2; i<=254; i++) apply_cycle(8'd100, 8'd100); // Chu kỳ 2-254
        apply_cycle(8'd101, 8'd100); // Chu kỳ 255
        apply_cycle(8'd101, 8'd100); // Chu kỳ 256
        
        if (uo_out !== 8'd3) $display("FAIL: CA 1, ky vong 3, nhan duoc %0d", uo_out);
        else $display("PASS: CA 1 (Ket qua = 3)");

        // =====================================================================
        // CA KIỂM THỬ 2: Cửa sổ mới bắt đầu ngay lập tức
        // =====================================================================
        apply_cycle(8'd101, 8'd100);
        if (uo_out !== 8'd1) $display("FAIL: CA 2, ky vong 1, nhan duoc %0d", uo_out);
        else $display("PASS: CA 2 (Ket qua = 1)");

        // =====================================================================
        // CA KIỂM THỬ 3: Bằng ngưỡng (Kỳ vọng: 0)
        // =====================================================================
        reset_dut();
        for (int i=1; i<=256; i++) apply_cycle(8'd100, 8'd100);
        if (uo_out !== 8'd0) $display("FAIL: CA 3, ky vong 0, nhan duoc %0d", uo_out);
        else $display("PASS: CA 3 (Ket qua = 0)");

        // =====================================================================
        // CA KIỂM THỬ 4: Tràn số (Tất cả đều vượt, Kỳ vọng: 256)
        // =====================================================================
        reset_dut();
        for (int i=1; i<=256; i++) apply_cycle(8'd101, 8'd100);
        // Kết quả 256 = uo_out = 0, uio_out[1] = 1
        if (uo_out !== 8'd0 || uio_out[1] !== 1'b1) 
            $display("FAIL: CA 4, ky vong 256, nhan duoc uo_out=%0d, uio_out[1]=%0d", uo_out, uio_out[1]);
        else $display("PASS: CA 4 (Ket qua = 256)");

        $display("Testbench finished.");
        $finish(0);
    end
endmodule
