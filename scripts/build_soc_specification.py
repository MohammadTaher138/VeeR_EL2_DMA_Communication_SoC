import os
import sys
import subprocess
import time

from make_spec_common import create_specification_document, add_header_footer
from make_spec_sections_1_5 import (
    build_cover_and_control, build_section_1, build_section_2,
    build_section_3, build_section_4, build_section_5
)
from make_spec_sections_6_10 import (
    build_section_6, build_section_7, build_section_8,
    build_section_9, build_section_10
)
from make_spec_sections_11_15 import (
    build_section_11, build_section_12, build_section_13,
    build_section_14, build_section_15
)

def main():
    print("================================================================================")
    print("STARTING BUILD: VeeR EL2 Communication SoC Hardware Specification")
    print("================================================================================")
    
    output_docx = "/home/student/Documents/Taher_152/Soc_Project/Docx/VeeR_EL2_Communication_SoC_Specification.docx"
    output_dir = "/home/student/Documents/Taher_152/Soc_Project/Docx"
    output_pdf = "/home/student/Documents/Taher_152/Soc_Project/Docx/VeeR_EL2_Communication_SoC_Specification.pdf"
    
    t0 = time.time()
    
    print("[1/5] Initializing document structure and typography...")
    doc = create_specification_document()
    
    print("[2/5] Building Cover Page, Revision History, and Sections 1 to 5...")
    build_cover_and_control(doc)
    build_section_1(doc)
    build_section_2(doc)
    build_section_3(doc)
    build_section_4(doc)
    build_section_5(doc)
    
    print("[3/5] Building Registers, Control/Data Paths, DMA, and Peripherals (Sections 6 to 10)...")
    build_section_6(doc)
    build_section_7(doc)
    build_section_8(doc)
    build_section_9(doc)
    build_section_10(doc)
    
    print("[4/5] Building Interrupts, Clock/Reset, Verification, and Conclusions (Sections 11 to 15)...")
    build_section_11(doc)
    build_section_12(doc)
    build_section_13(doc)
    build_section_14(doc)
    build_section_15(doc)
    
    print("[5/5] Finalizing headers, footers, and saving DOCX...")
    add_header_footer(doc)
    
    doc.save(output_docx)
    print(f"-> Successfully saved DOCX: {output_docx} ({os.path.getsize(output_docx):,} bytes)")
    
    print("\nConverting DOCX to PDF using LibreOffice headless engine...")
    cmd = f"libreoffice --headless --convert-to pdf {output_docx} --outdir {output_dir}"
    res = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    if res.returncode != 0:
        print(f"ERROR: PDF conversion failed: {res.stderr}")
        sys.exit(1)
        
    print(f"-> Successfully generated PDF: {output_pdf} ({os.path.getsize(output_pdf):,} bytes)")
    print(f"Build completed in {time.time() - t0:.2f} seconds!")
    print("================================================================================")

if __name__ == '__main__':
    main()
