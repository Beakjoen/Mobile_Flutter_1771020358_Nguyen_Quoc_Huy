using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

/// <summary>
/// PHẦN 2: [xxx]_TransactionCategories - Dùng cho thu chi nội bộ khác
/// Id, Name, Type (Thu/Chi)
/// </summary>
[Table("358_TransactionCategories")]
public class TransactionCategory
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    /// <summary>Thu hoặc Chi</summary>
    public TransactionCategoryType Type { get; set; }
}

public enum TransactionCategoryType
{
    Thu = 0,
    Chi = 1
}
