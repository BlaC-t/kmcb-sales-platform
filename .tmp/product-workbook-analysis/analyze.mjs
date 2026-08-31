import fs from 'node:fs/promises';
import path from 'node:path';
import { FileBlob, SpreadsheetFile } from '@oai/artifact-tool';

const files = [
  '/Users/zhiyu/Library/CloudStorage/OneDrive-Personal/数峰/销售平台/圆振动筛产品参数表-260626.xlsx',
  '/Users/zhiyu/Library/CloudStorage/OneDrive-Personal/数峰/销售平台/洗矿机产品在销售版本明细表(2026.04洗矿机更新).xlsx',
  '/Users/zhiyu/Library/CloudStorage/OneDrive-Personal/数峰/销售平台/直线筛产品在销售版本明细表-2026.4.20.xlsx',
];

const outputDir = path.resolve('.tmp/product-workbook-analysis');
await fs.mkdir(path.join(outputDir, 'previews'), { recursive: true });

const report = [];
for (const [fileIndex, file] of files.entries()) {
  const input = await FileBlob.load(file);
  const workbook = await SpreadsheetFile.importXlsx(input);
  const overview = await workbook.inspect({
    kind: 'workbook,sheet,table',
    maxChars: 12000,
    tableMaxRows: 12,
    tableMaxCols: 18,
    tableMaxCellChars: 120,
  });

  const sheetOverview = await workbook.inspect({
    kind: 'sheet',
    include: 'id,name',
    maxChars: 6000,
  });

  const sheetNames = sheetOverview.ndjson
    .split('\n')
    .filter(Boolean)
    .map((line) => JSON.parse(line).name);
  const sheetDetails = [];
  for (const [sheetIndex, sheetName] of sheetNames.entries()) {
    const sheet = workbook.worksheets.getItem(sheetName);
    const used = sheet.getUsedRange(true);
    const values = used.values;
    const detectedHeaders = [];
    let activeHeader = null;
    let modelRows = 0;
    let variantRowsWithoutModel = 0;
    let noteRows = 0;
    let titleRows = 0;
    const modelCodes = [];
    for (const [rowIndex, row] of values.entries()) {
      const cells = row.map((value) => String(value ?? '').trim());
      const nonEmpty = cells.filter(Boolean);
      const modelCol = cells.findIndex((value) => value === '型号规格' || value === '规格型号');
      const drawingCol = cells.findIndex((value) => value === '图号');
      if (modelCol >= 0) {
        activeHeader = { row: rowIndex + 1, modelCol, drawingCol };
        detectedHeaders.push({ row: rowIndex + 1, modelCol: modelCol + 1, drawingCol: drawingCol + 1 });
        continue;
      }
      if (cells[0]?.startsWith('注')) {
        noteRows += 1;
        activeHeader = null;
        continue;
      }
      if (nonEmpty.length === 1 && rowIndex < values.length - 1) {
        titleRows += 1;
      }
      if (!activeHeader) continue;
      const model = cells[activeHeader.modelCol];
      const drawing = activeHeader.drawingCol >= 0 ? cells[activeHeader.drawingCol] : '';
      if (model) {
        modelRows += 1;
        modelCodes.push(model.replaceAll(' ', '').toUpperCase());
      }
      else if (drawing) variantRowsWithoutModel += 1;
    }
    const region = await workbook.inspect({
      kind: 'region',
      sheetId: sheetName,
      range: used.address,
      maxChars: 30000,
      tableMaxRows: 100,
      tableMaxCols: 24,
      tableMaxCellChars: 160,
    });
    const formulas = await workbook.inspect({
      kind: 'formula',
      sheetId: sheetName,
      range: used.address,
      maxChars: 5000,
      options: { maxResults: 100 },
    });
    const style = await workbook.inspect({
      kind: 'computedStyle',
      sheetId: sheetName,
      range: used.address,
      maxChars: 5000,
    });
    sheetDetails.push({
      sheetName,
      usedRange: used.address,
      region: region.ndjson,
      formulas: formulas.ndjson,
      style: style.ndjson,
      structuralSummary: {
        detectedHeaders,
        modelRows,
        variantRowsWithoutModel,
        noteRows,
        titleRows,
        uniqueModelCodes: new Set(modelCodes).size,
        duplicateModelCodes: [...new Set(modelCodes.filter((code, index) => modelCodes.indexOf(code) !== index))],
      },
    });

    const preview = await workbook.render({
      sheetName,
      autoCrop: 'all',
      scale: 1.4,
      format: 'png',
    });
    const bytes = new Uint8Array(await preview.arrayBuffer());
    await fs.writeFile(
      path.join(outputDir, 'previews', `${fileIndex + 1}-${sheetIndex + 1}-${sheetName.replaceAll('/', '_')}.png`),
      bytes,
    );
  }

  report.push({
    file,
    fileName: path.basename(file),
    overview: overview.ndjson,
    sheets: sheetOverview.ndjson,
    sheetDetails,
  });
}

await fs.writeFile(path.join(outputDir, 'overview.json'), JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
