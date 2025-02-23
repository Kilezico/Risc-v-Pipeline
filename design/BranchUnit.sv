`timescale 1ns / 1ps

module BranchUnit #(
    parameter PC_W = 9
) (
    input logic [PC_W-1:0] Cur_PC,
    input logic [31:0] Imm,
    input logic Branch,
    input logic [31:0] AluResult,
    output logic [31:0] PC_Imm,
    output logic [31:0] PC_Four,
    output logic [PC_W-1:0] BrPC,
    output logic PcSel,
    input logic EhJAL,
    input logic EhJALR,
    input logic [2:0] Funct3,
    input logic [6:0] opcode
);

  logic Branch_Sel;
  logic [31:0] PC_Full;
  logic [31:0] BrPC_Full; // Variavel temporaria para calculo de BrPC

  assign PC_Full = {{23{Cur_PC[PC_W-1]}}, Cur_PC};
  always_comb begin
  $display("Time: %0t | Cur_PC = %h, PC_Full = %h", $time, Cur_PC, PC_Full);
  end

  assign PC_Imm = PC_Full + Imm;
  assign PC_Four = PC_Full + 32'd4;

  // Determinando se alguma condicao de branch foi acionada, usando o Funct3 para saber o que fazer
  always_comb begin
    if (EhJALR) begin //BEQ -> Desvio se SrcA == SrcB (Aqui tem problema, o Funct3 de BEQ e de JALR sao iguais, tenho que tratar)
        Branch_Sel = 1;
    end else begin
        case(Funct3)
            3'b000: Branch_Sel = Branch && AluResult[0]; // De fato o BEQ
            3'b001: Branch_Sel = Branch && !AluResult[0]; // BNE -> Desvio se SrcA != SrcB
            3'b100: Branch_Sel = Branch && AluResult[0]; // BLT -> Desvio se SrcA < SrcB
            3'b101: Branch_Sel = Branch && !AluResult[0]; // BGE -> BGE: Desvio se SrcA >= SrcB
            default: Branch_Sel = 0; // Nao eh uma instrucao de branch
        endcase
    end
  end

  // Calculando o o valor do próximo PC
  always_comb begin
    if (EhJAL) begin
        BrPC_Full = PC_Imm & ~32'b1; // JAL: PC + Imm (Incondicional)
        BrPC = BrPC_Full[PC_W-1:0];  // Truncar para PC_W bits -> Necessario porque o pc tem 9 bits, mas BrPC tem 32 bits
        PcSel = 1;
    end else if (EhJALR) begin
        BrPC_Full = AluResult & ~32'b1; // JALR: rs1 + imm (Incondicional)
        BrPC = BrPC_Full[PC_W-1:0];     // Truncar para PC_W bits -> Dessa forma, garantimos que o endereco cabe no PC
        PcSel = 1;
    end else if (Branch_Sel) begin
        BrPC_Full = PC_Imm & ~32'b1; // Branch: PC + Imm (se acontecer)
        BrPC = BrPC_Full[PC_W-1:0];  // Truncar para PC_W bits
        PcSel = 1;
    end else begin
        BrPC = 0; // Nenhum desvio
        PcSel = 0;
    end
  end



endmodule
