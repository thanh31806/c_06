`timescale 1ns/1ps

module c06_core_tb;
    // Khai báo tín hiệu
    logic clk, rst_n;
    logic [7:0] sample_in, threshold;
    logic [7:0] window_count;
    logic [8:0] event_count, result_count;
    logic window_done;

    // Khởi tạo module cần kiểm tra (DUT - Device Under Test)
    c06_core dut (.*);

    // Tạo xung clock chu kỳ 10ns
    always #5 clk = ~clk;

    // Task nạp một mẫu dữ liệu vào mạch
    task automatic apply_cycle(input logic [7:0] x);
        begin
            sample_in = x;
            @(posedge clk);
            #1; // Đợi 1ns sau cạnh clock để quan sát kết quả
        end
    endtask

    // Task reset mạch
    task automatic reset_dut;
        begin
            rst_n = 0;
            sample_in = 0;
            repeat(2) @(posedge clk); // Giữ reset 2 chu kỳ
            rst_n = 1;
            #1;
        end
    endtask

    initial begin
        // Khởi tạo giá trị ban đầu
        clk = 0;
        rst_n = 1;
        sample_in = 0;
        threshold = 8'd100; // Đặt ngưỡng so sánh là 100

        reset_dut();

        // =====================================================================
        // CA KIỂM THỬ 1: Kiểm tra thời điểm chốt kết quả (Quan trọng nhất)
        // Mục đích: Đảm bảo mẫu của chu kỳ 256 được tính vào cửa sổ hiện tại,
        // và bộ đếm được xoá đúng lúc. Đặt sự kiện ở chu kỳ 1 (mép đầu), 
        // chu kỳ 255 (mép cuối) và chu kỳ 256 (chu kỳ chốt).
        // Kỳ vọng: result_count = 3.
        // =====================================================================
        apply_cycle(8'd101); // Chu kỳ 1: Vượt ngưỡng (101 > 100)
        for (int i=2; i<=254; i++) apply_cycle(8'd100); // Chu kỳ 2-254: Không vượt (100 == 100)
        apply_cycle(8'd101); // Chu kỳ 255: Vượt ngưỡng
        apply_cycle(8'd101); // Chu kỳ 256: Vượt ngưỡng (và là chu kỳ kết thúc)
        
        // Kiểm tra kết quả sau khi cửa sổ kết thúc
        assert(window_done == 1) else $fatal(1, "Loi: window_done khong bat tai chu ky 256");
        assert(result_count == 9'd3) else $fatal(1, "Loi: Ket qua sai, ky vong 3, nhan duoc %0d", result_count);
        assert(window_count == 0) else $fatal(1, "Loi: window_count khong reset");
        assert(event_count == 0) else $fatal(1, "Loi: event_count khong reset");

        // =====================================================================
        // CA KIỂM THỬ 2: Kiểm tra cửa sổ mới bắt đầu ngay lập tức
        // Mục đích: Đảm bảo không có chu kỳ chết (no dead cycle) giữa 2 cửa sổ.
        // Kỳ vọng: window_count = 1, event_count = 1.
        // =====================================================================
        apply_cycle(8'd101); // Mẫu đầu tiên của cửa sổ 2
        assert(window_count == 8'd1) else $fatal(1, "Loi: Cua so 2 khong bat dau dung");
        assert(event_count == 9'd1) else $fatal(1, "Loi: Bo dem su kien cua cua so 2 sai");

        // =====================================================================
        // CA KIỂM THỬ 3: Kiểm tra quy ước biên (Bằng ngưỡng không tính)
        // Mục đích: Đảm bảo mạch dùng dấu '>' chứ không dùng '>='.
        // Nạp 255 mẫu bằng 100 (bằng ngưỡng) -> Không tính là vượt.
        // Kỳ vọng: result_count vẫn giữ nguyên là 1.
        // =====================================================================
        for (int i=2; i<=256; i++) apply_cycle(8'd100); 
        assert(result_count == 9'd1) else $fatal(1, "Loi: Mau bang nguong bi tinh sai");

        // =====================================================================
        // CA KIỂM THỬ 4: Kiểm tra tràn số (Cận trên của kết quả)
        // Mục đích: Đảm bảo thanh ghi chốt đủ rộng (9 bit) để chứa kết quả 256.
        // Nạp 256 mẫu 101 (tất cả đều vượt) -> Kết quả phải là 256.
        // =====================================================================
        for (int i=1; i<=256; i++) apply_cycle(8'd101);
        assert(result_count == 9'd256) else $fatal(1, "Loi: Ket qua toi da sai, ky vong 256");

        // Nếu chạy qua hết các assert trên mà không bị $fatal, in ra PASS
        $display("C06 core verification PASS");
        $finish;
    end
endmodule
