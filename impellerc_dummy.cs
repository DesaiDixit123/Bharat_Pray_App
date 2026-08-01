using System;
using System.IO;

class Program {
    static void Main(string[] args) {
        Console.WriteLine("DUMMY_IMPELLERC_RAN");
        string inputPath = null;
        string slPath = null;
        string spirvPath = null;

        for (int i = 0; i < args.Length; i++) {
            if (args[i] == "--input" && i + 1 < args.Length) inputPath = args[i + 1];
            if (args[i] == "--sl" && i + 1 < args.Length) slPath = args[i + 1];
            if (args[i] == "--spirv" && i + 1 < args.Length) spirvPath = args[i + 1];
        }

        if (!string.IsNullOrEmpty(slPath)) {
            if (!string.IsNullOrEmpty(inputPath) && File.Exists(inputPath)) {
                File.Copy(inputPath, slPath, true);
            } else {
                File.WriteAllText(slPath, "// dummy shader");
            }
        }

        if (!string.IsNullOrEmpty(spirvPath)) {
            // Minimum valid SPIR-V binary header
            byte[] spirvHeader = new byte[] { 
                0x03, 0x02, 0x23, 0x07, 
                0x00, 0x00, 0x01, 0x00, 
                0x00, 0x00, 0x08, 0x00, 
                0x01, 0x00, 0x00, 0x00, 
                0x00, 0x00, 0x00, 0x00 
            };
            File.WriteAllBytes(spirvPath, spirvHeader);
        }
    }
}
