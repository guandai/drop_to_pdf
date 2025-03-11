/**
 * @param {number[]} nums
 * @return {number}
 */
function rob(nums) {
    if (nums.length === 0) return 0;
    if (nums.length === 1) return nums[0];
    if (nums.length === 2) return Math.max(nums[0], nums[1]);

    // 计算不偷第一间房的情况
    let rob1 = robHelper(nums.slice(1));
    // 计算不偷最后一间房的情况
    let rob2 = robHelper(nums.slice(0, -1));

    // 返回两种情况中的最大值
    return Math.max(rob1, rob2);
}

// 辅助函数，计算给定数组的最大金额
function robHelper(nums) {
    let prevMax = 0;
    let currMax = 0;

    for (let num of nums) {
        let temp = currMax;
        currMax = Math.max(prevMax + num, currMax);
        prevMax = temp;
    }

    return currMax;
}

// 测试用例
console.log(rob([2,3,2])); // 输出：3
console.log(rob([1,2,3,1])); // 输出：4
console.log(rob([1,2,3])); // 输出：3
