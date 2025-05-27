const MilkSupplyChain = artifacts.require("MilkSupplyChain");

contract("MilkSupplyChain", (accounts) => {
  const [admin, producer, reseller] = accounts;
  let instance;

  beforeEach(async () => {
    instance = await MilkSupplyChain.new({ from: admin }); // admin est déjà owner + admin
    await instance.setProducer(producer, { from: admin });
    await instance.setReseller(reseller, 1000, { from: admin }); // 👈 Ajoute maxQuantity
  });

  it("should produce milk successfully", async () => {
    await instance.produce(100, { from: producer });
    const stock = await instance.stockBalance(producer);
    assert.equal(stock.toString(), "100", "Stock should be 100");
  });

  it("should transfer stock to reseller", async () => {
    await instance.produce(200, { from: producer });

    // 👇 on utilise le batchId retourné implicitement
    await instance.transferStock(reseller, 50, 0, { from: producer });

    const resellerStock = await instance.stockBalance(reseller);
    assert.equal(resellerStock.toString(), "50", "Reseller should have 50");
  });

  it("should not allow unauthorized users to produce", async () => {
    try {
      await instance.produce(100, { from: reseller });
      assert.fail("Reseller should not be able to produce");
    } catch (error) {
      assert(error.message.includes("Not an authorized producer"), "Expected authorization error");
    }
  });
});
