import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

# Color Palette Constants (Professional Engineering Spec Style)
COLOR_NAVY_HEX = "1F4E79"       # Primary Headers / Main Accent
COLOR_SLATE_HEX = "2F5597"      # Subheadings
COLOR_RUST_HEX = "C65911"       # Important / Highlights
COLOR_DARK_TEXT_HEX = "262626"  # Body text
COLOR_MUTED_GRAY = "595959"     # Metadata / Captions
COLOR_BG_LIGHT = "F4F6F9"       # Zebra row background
COLOR_CALLOUT_BG = "F0F4F8"     # Note box background
COLOR_WARN_BG = "FDF3EB"        # Warning box background

RGB_NAVY = RGBColor(31, 78, 121)
RGB_SLATE = RGBColor(47, 85, 151)
RGB_RUST = RGBColor(198, 89, 17)
RGB_TEXT = RGBColor(38, 38, 38)
RGB_MUTED = RGBColor(89, 89, 89)

def create_specification_document():
    doc = Document()
    
    # Configure 0.8 inch margins on all sides
    for section in doc.sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)
        section.page_width = Inches(8.5)
        section.page_height = Inches(11.0)
        
    return doc

def add_header_footer(doc):
    for s_idx, section in enumerate(doc.sections):
        if s_idx == 0:
            # First section (Cover page) has different header/footer
            section.different_first_page_header_footer = True
            header = section.first_page_header
            footer = section.first_page_footer
            hp = header.paragraphs[0]
            hp.text = ""
            fp = footer.paragraphs[0]
            fp.text = ""
            
        header = section.header
        hp = header.paragraphs[0]
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hrun = hp.add_run("VeeR EL2 Communication SoC | System Hardware Specification (SPEC-V1.0)")
        hrun.font.name = "Arial"
        hrun.font.size = Pt(8.5)
        hrun.font.italic = True
        hrun.font.color.rgb = RGB_MUTED
        
        footer = section.footer
        fp = footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        frun_left = fp.add_run("CONFIDENTIAL — SOC DESIGN & VERIFICATION SPECIFICATION\tPage ")
        frun_left.font.name = "Arial"
        frun_left.font.size = Pt(8.5)
        frun_left.font.color.rgb = RGB_MUTED
        
        # Add PAGE field
        _add_field(fp, "PAGE")
        frun_mid = fp.add_run(" of ")
        frun_mid.font.name = "Arial"
        frun_mid.font.size = Pt(8.5)
        frun_mid.font.color.rgb = RGB_MUTED
        
        # Add NUMPAGES field
        _add_field(fp, "NUMPAGES")

def _add_field(paragraph, field_text):
    run = paragraph.add_run()
    fldChar1 = OxmlElement('w:fldChar')
    fldChar1.set(qn('w:fldCharType'), 'begin')
    instrText = OxmlElement('w:instrText')
    instrText.set(qn('xml:space'), 'preserve')
    instrText.text = field_text
    fldChar2 = OxmlElement('w:fldChar')
    fldChar2.set(qn('w:fldCharType'), 'separate')
    fldChar3 = OxmlElement('w:fldChar')
    fldChar3.set(qn('w:fldCharType'), 'end')
    run._r.append(fldChar1)
    run._r.append(instrText)
    run._r.append(fldChar2)
    run._r.append(fldChar3)
    run.font.name = "Arial"
    run.font.size = Pt(8.5)
    run.font.color.rgb = RGB_MUTED

def set_cell_background(cell, fill_hex):
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    cell._tc.get_or_add_tcPr().append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=140, right=140):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def add_heading_1(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(16)
    run.bold = True
    run.font.color.rgb = RGB_NAVY
    return p

def add_heading_2(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(13)
    run.bold = True
    run.font.color.rgb = RGB_SLATE
    return p

def add_heading_3(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(11)
    run.bold = True
    run.font.color.rgb = RGBColor(51, 51, 51)
    return p

def add_body_p(doc, text, bold_prefix=None, space_after=5):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = 1.15
    if bold_prefix:
        brun = p.add_run(bold_prefix)
        brun.font.name = "Arial"
        brun.font.size = Pt(9.5)
        brun.bold = True
        brun.font.color.rgb = RGB_TEXT
    run = p.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(9.5)
    run.font.color.rgb = RGB_TEXT
    return p

def add_bullet_p(doc, text, bold_prefix=None):
    p = doc.add_paragraph(style='List Bullet')
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.line_spacing = 1.15
    if bold_prefix:
        brun = p.add_run(bold_prefix)
        brun.font.name = "Arial"
        brun.font.size = Pt(9.5)
        brun.bold = True
        brun.font.color.rgb = RGB_TEXT
    run = p.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(9.5)
    run.font.color.rgb = RGB_TEXT
    return p

def add_callout(doc, text, title="NOTE", alert_type="NOTE"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tblPr = tbl._tbl.tblPr
    
    border_color = COLOR_NAVY_HEX if alert_type == "NOTE" else (COLOR_RUST_HEX if alert_type in ["IMPORTANT", "WARNING"] else "385723")
    bg_color = COLOR_CALLOUT_BG if alert_type == "NOTE" else (COLOR_WARN_BG if alert_type in ["IMPORTANT", "WARNING"] else "F2F8F2")
    
    borders = parse_xml(f'<w:tblBorders {nsdecls("w")}><w:top w:val="none"/><w:bottom w:val="none"/><w:left w:val="single" w:sz="36" w:space="0" w:color="{border_color}"/><w:right w:val="none"/><w:insideH w:val="none"/><w:insideV w:val="none"/></w:tblBorders>')
    tblPr.append(borders)
    
    cell = tbl.cell(0, 0)
    set_cell_background(cell, bg_color)
    set_cell_margins(cell, top=100, bottom=100, left=180, right=180)
    cell.width = Inches(6.9)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.line_spacing = 1.15
    
    run_title = p.add_run(f"[{title}] ")
    run_title.bold = True
    run_title.font.name = "Arial"
    run_title.font.size = Pt(9.5)
    run_title.font.color.rgb = RGB_NAVY if alert_type == "NOTE" else (RGB_RUST if alert_type in ["IMPORTANT", "WARNING"] else RGBColor(56, 87, 35))
    
    run_text = p.add_run(text)
    run_text.font.name = "Arial"
    run_text.font.size = Pt(9.5)
    run_text.font.color.rgb = RGB_TEXT
    
    # spacing
    doc.add_paragraph().paragraph_format.space_after = Pt(2)

def add_figure(doc, image_path, figure_label, caption_text, width=Inches(6.4)):
    p_img = doc.add_paragraph()
    p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_img.paragraph_format.space_before = Pt(8)
    p_img.paragraph_format.space_after = Pt(4)
    run = p_img.add_run()
    run.add_picture(image_path, width=width)
    
    p_cap = doc.add_paragraph()
    p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_cap.paragraph_format.space_before = Pt(2)
    p_cap.paragraph_format.space_after = Pt(10)
    p_cap.paragraph_format.keep_with_next = False
    
    run_lbl = p_cap.add_run(f"{figure_label}: ")
    run_lbl.font.name = "Arial"
    run_lbl.font.size = Pt(9.0)
    run_lbl.bold = True
    run_lbl.font.color.rgb = RGB_NAVY
    
    run_text = p_cap.add_run(caption_text)
    run_text.font.name = "Arial"
    run_text.font.size = Pt(9.0)
    run_text.font.italic = True
    run_text.font.color.rgb = RGB_MUTED

def create_styled_table(doc, headers, data, col_widths=None):
    tbl = doc.add_table(rows=len(data) + 1, cols=len(headers))
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tblPr = tbl._tbl.tblPr
    borders = parse_xml(f'<w:tblBorders {nsdecls("w")}><w:top w:val="single" w:sz="4" w:space="0" w:color="D9D9D9"/><w:bottom w:val="single" w:sz="8" w:space="0" w:color="1F4E79"/><w:left w:val="none"/><w:right w:val="none"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="E0E0E0"/><w:insideV w:val="none"/></w:tblBorders>')
    tblPr.append(borders)

    hdr_cells = tbl.rows[0].cells
    hdr_tr = tbl.rows[0]._tr.get_or_add_trPr()
    hdr_tr.append(parse_xml(f'<w:tblHeader {nsdecls("w")}/>'))
    hdr_tr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))

    for i, title in enumerate(headers):
        cell = hdr_cells[i]
        set_cell_background(cell, COLOR_NAVY_HEX)
        set_cell_margins(cell, top=100, bottom=100, left=120, right=120)
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.space_before = Pt(1)
        p.paragraph_format.space_after = Pt(1)
        run = p.add_run(title)
        run.bold = True
        run.font.name = "Arial"
        run.font.size = Pt(9.0)
        run.font.color.rgb = RGBColor(255, 255, 255)

    for r_idx, row_data in enumerate(data):
        row_cells = tbl.rows[r_idx + 1].cells
        row_tr = tbl.rows[r_idx + 1]._tr.get_or_add_trPr()
        row_tr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))
        bg_color = "FFFFFF" if r_idx % 2 == 0 else COLOR_BG_LIGHT
        for c_idx, val in enumerate(row_data):
            cell = row_cells[c_idx]
            set_cell_background(cell, bg_color)
            set_cell_margins(cell, top=80, bottom=80, left=120, right=120)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_before = Pt(1)
            p.paragraph_format.space_after = Pt(1)
            run = p.add_run(str(val))
            run.font.name = "Arial"
            run.font.size = Pt(8.5)
            run.font.color.rgb = RGB_TEXT

    if col_widths:
        for row in tbl.rows:
            for idx, width in enumerate(col_widths):
                row.cells[idx].width = width

    doc.add_paragraph().paragraph_format.space_after = Pt(4)
    return tbl
