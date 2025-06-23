export function decodeRevertReason(data) {
  if (!data) return "";

  let hex = data.startsWith("0x") ? data.slice(2) : data;

  const strHex = hex.slice(136);
  let str = "";
  for (let i = 0; i < strHex.length; i += 2) {
    const code = parseInt(strHex.substr(i, 2), 16);
    if (code) str += String.fromCharCode(code);
  }
  console.log(str);
  return str;
}
