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
    output logic [31:0] BrPC,
    output logic PcSel,
    input logic EhJAL,
    input logic EhJALR,
    input logic [2:0] Funct3
);

  logic Branch_Sel;
  logic [31:0] PC_Full;

  assign PC_Full = {23'b0, Cur_PC};

  assign PC_Imm = PC_Full + Imm;
  assign PC_Four = PC_Full + 32'd4;

  // Determinando se alguma condicao de branch foi acionada, usando o Funct3 para saber o que fazer
  always_comb begin
    case(Funct3)
        3'b000: Branch_Sel = Branch && AluResult[0]; // De fato o BEQ
        3'b001: Branch_Sel = Branch && !AluResult[0]; // BNE -> Desvio se SrcA != SrcB
        3'b100: Branch_Sel = Branch && AluResult[0]; // BLT -> Desvio se SrcA < SrcB
        3'b101: Branch_Sel = Branch && !AluResult[0]; // BGE -> BGE: Desvio se SrcA >= SrcB
        default: Branch_Sel = 0; // Nao eh uma instrucao de branch
    endcase
  end

  // Calculando o o valor do próximo PC
  always_comb begin
    if (EhJAL) begin
        BrPC = PC_Imm;  // JAL: PC + Imm (Incondicional)
        PcSel = 1;
    end else if (EhJALR) begin
        BrPC = AluResult & ~32'd1; // JALR: rs1 + imm (Incondicional)
        PcSel = 1;
    end else if (Branch_Sel) begin
        BrPC = PC_Imm; // Branch: PC + Imm (se acontecer)
        PcSel = 1;
    end else begin
        BrPC = 0; // Nenhum desvio
        PcSel = 0;
    end
  end



endmodule
