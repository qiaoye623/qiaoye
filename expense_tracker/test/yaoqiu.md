// 新用户首次创建账本时，只创建1个默认账本
function initDefaultBook(userId) {
  // 先查询用户是否已有账本
  const existingBooks = queryBooksByUserId(userId);
  if (existingBooks.length === 0) {
    // 无账本，创建1个默认个人账本
    createBook({
      userId: userId,
      name: "个人账本",
      isDefault: true,
      createTime: new Date()
    });
  }
}

// 设为默认账本逻辑（必须保证全局唯一）
function setDefaultBook(userId, bookId) {
  // 先把该用户所有账本的isDefault设为false
  updateAllBooksByUserId(userId, { isDefault: false });
  // 再把当前选中的设为true
  updateBook(bookId, { isDefault: true });
}




// 新用户首次创建账户时，只创建3个基础账户
function initDefaultAccounts(userId) {
  const existingAccounts = queryAccountsByUserId(userId);
  if (existingAccounts.length === 0) {
    const defaultAccounts = [
      { name: "微信钱包", type: "wechat", balance: 0.00 },
      { name: "支付宝钱包", type: "alipay", balance: 0.00 },
      { name: "现金", type: "cash", balance: 0.00 }
    ];
    defaultAccounts.forEach(acc => {
      createAccount({ userId, ...acc });
    });
  }
}

// 新增账户时的去重校验
function addAccount(userId, name, type) {
  const isExist = queryAccountByNameAndType(userId, name, type);
  if (isExist) {
    throw new Error("该账户已存在，请修改名称或类型");
  }
  createAccount({ userId, name, type, balance: 0.00 });
}


果验收清单（你可以直接对照检查）
✅ 首次进入账本管理页，只有 1 个「个人账本」，且带有「默认」标签
✅ 新增账本时，无法创建和已有账本重名的账本
✅ 只能有 1 个默认账本，切换默认后，其他账本的「默认」标签消失
✅ 资产账户页，只有 1 个微信、1 个支付宝、1 个现金，无重复
✅ 记账选择账户弹窗里，只有 3 个基础账户，无重复选项
✅ 账户余额会随记账操作实时更新，不再全部为 0.00