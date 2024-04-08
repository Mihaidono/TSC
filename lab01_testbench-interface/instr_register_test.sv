/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/

module instr_register_test
  import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
(
    input  logic         clk,
    output logic         load_en,
    output logic         reset_n,
    output operand_t     operand_a,
    output operand_t     operand_b,
    output opcode_t      opcode,
    output address_t     write_pointer,
    output address_t     read_pointer,
    input  instruction_t instruction_word
);

  timeunit 1ns / 1ns;
  parameter READ_NUMBER = 30, WRITE_NUMBER = 30;
  parameter WRITE_ORDER = 2, READ_ORDER = 2;
  parameter CASE_NAME;
  int number_of_errors_per_test = 0;
  int failed_tests_per_test = 0;
  int seed = 555;
  instruction_t iw_reg_test[0:31];

  initial begin
    $display("\n\n***********************************************************");
    $display("***  THIS IS A SELF-CHECKING TESTBENCH (YET). YOU DON'T ***");
    $display("***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display("***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display("***********************************************************");

    $display("\nReseting the instruction register...");
    write_pointer = 5'h00;  // initialize write pointer
    read_pointer  = 5'h1F;  // initialize read pointer
    load_en       = 1'b0;  // initialize load control line
    reset_n <= 1'b0;  // assert reset_n (active low)
    foreach (iw_reg_test[i]) begin
      iw_reg_test[i] = '{opc: ZERO, default: 0};
    end
    repeat (2) @(posedge clk);  // hold in reset for 2 clock cycles
    reset_n = 1'b1;  // deassert reset_n (active low)

    $display("\nWriting values to register stack...");
    @(posedge clk) load_en = 1'b1;  // enable writing to register
    // A.M. 9:19 - 11/3/2024 
    //repeat (3) begin
    repeat (WRITE_NUMBER) begin
      @(posedge clk) randomize_transaction;
      @(negedge clk) print_transaction;
      save_test_data;
    end
    @(posedge clk) load_en = 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written...");
    // A.M. 9:19 - 11/3/2024 
    // for (int i=0; i<=2; i++) begin
    for (int i = 0; i <= READ_NUMBER; i++) begin
      // later labs will replace this loop with iterating through a
      // scoreboard to determine which addresses were written and
      // the expected values to be read back
      @(posedge clk)
        case (READ_ORDER)
          0: read_pointer = i;
          1: read_pointer = $unsigned($random) % 32;
          2: read_pointer = 31 - (i % 32);
        endcase
      @(negedge clk) print_results;
      check_result;

    end

    @(posedge clk);
    $display("\nNumber of errors per transactions: %0d", number_of_errors_per_test);
    $display("\nNumber of failed tests: %0d", failed_tests_per_test);
    $display("\nFailed tests percentage: %0.2f%%", (failed_tests_per_test * 100.0) / WRITE_NUMBER);

    $display("\n\n***********************************************************");
    $display("***  THIS IS A SELF-CHECKING TESTBENCH (YET). YOU DON'T ***");
    $display("***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display("***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display("***********************************************************");
    $finish;
  end

  function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //
    static int incremental_value = 0;
    static int decremental_value = 31;
    operand_a <= $random(seed) % 16;  // between -15 and 15
    operand_b <= $unsigned($random) % 16;  // between 0 and 15
    opcode    <= opcode_t'($unsigned($random) % 8);  // between 0 and 7, cast to opcode_t type
    case (WRITE_ORDER)
      0: write_pointer <= incremental_value++;
      1: write_pointer <= $unsigned($random) % 32;
      2: write_pointer <= decremental_value--;
    endcase
  endfunction : randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d", operand_a);
    $display("  operand_b = %0d\n", operand_b);
  endfunction : print_transaction

  function void print_results;
    $display("Read from register location %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d", instruction_word.op_a);
    $display("  operand_b = %0d", instruction_word.op_b);
    $display("  result = %0d\n", instruction_word.result);
    //
    // TEMA : DE SCRIS IN FISIER DETALII DESPRE TEST, DACA A TRECUT, CE A TRECUT, CU CE PARAMETRII AM APELAT ETC
    //
  endfunction : print_results

  function void check_result;
    static bit has_error_arisen = 1'b0;
    if (iw_reg_test[read_pointer].opc != instruction_word.opc) begin
      number_of_errors_per_test++;
      $display("Operation Code of transaction does not match to the testbench one!");
      has_error_arisen = 1'b1;
    end

    if (iw_reg_test[read_pointer].op_a != instruction_word.op_a) begin
      number_of_errors_per_test++;
      $display("Operand A of transaction does not match to the testbench one!");
      has_error_arisen = 1'b1;
    end

    if (iw_reg_test[read_pointer].op_b != instruction_word.op_b) begin
      number_of_errors_per_test++;
      $display("Operand B of transaction does not match to the testbench one!");
      has_error_arisen = 1'b1;
    end

    if (iw_reg_test[read_pointer].result != instruction_word.result) begin
      number_of_errors_per_test++;
      $display("Result of transaction does not match to the testbench one!");
      has_error_arisen = 1'b1;
    end
    if (has_error_arisen) begin
      $display("Transaction {%s, %0d, %0d, %0d} failed!\n\n", instruction_word.opc,
               instruction_word.op_a, instruction_word.op_b, instruction_word.result);
      failed_tests_per_test++;
      has_error_arisen = 1'b0;
    end
  endfunction : check_result

  function void save_test_data;
    operand_result_t local_result;
    case (opcode)
      ZERO:  local_result = {64{1'b0}};
      PASSA: local_result = operand_a;
      PASSB: local_result = operand_b;
      ADD:   local_result = operand_a + operand_b;
      SUB:   local_result = operand_a - operand_b;
      MULT:  local_result = operand_a * operand_b;
      DIV:   local_result = operand_b ? operand_a / operand_b : {64{1'b0}};
      MOD:   local_result = operand_b ? operand_a % operand_b : {64{1'b0}};
    endcase
    iw_reg_test[write_pointer] = '{opcode, operand_a, operand_b, local_result};
  endfunction : save_test_data

  function void save_test_data;
    
  endfunction : save_test_data
endmodule : instr_register_test
