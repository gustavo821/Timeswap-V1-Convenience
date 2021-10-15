import { advanceTimeAndBlock, getBlock } from './Helper'
import { testTokenNew } from './TestToken'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { now } from '../shared/Helper'
import type { TimeswapFactory as Factory } from '../../typechain/TimeswapFactory'
import { Convenience, convenienceInit } from './Convenience'

import type { TestToken } from '../../typechain/TestToken'
import { ethers } from 'hardhat'
import {
  NewLiquidityParams,
  AddLiquidityParams,
  RemoveLiquidityParams,
  LendGivenBondParams,
  LendGivenInsuranceParams,
  LendGivenPercentParams,
  CollectParams,
  BorrowGivenDebtParams,
  BorrowGivenCollateralParams,
  BorrowGivenPercentParams,
  RepayParams,
} from '../types'
import { BorrowMathCallee, LendMathCallee, MintMathCallee, TimeswapPair } from '../../typechain'

let assetValue = 100000n ** 100000n
let collateralValue = 100000n ** 100000n

export async function constructorFixture(
  assetValue: bigint,
  collateralValue: bigint,
  maturity: bigint,
  signerWithAddress: SignerWithAddress
) {
  const assetToken = await testTokenNew('DAI', 'DAI', assetValue)
  const collateralToken = await testTokenNew('Matic', 'MATIC', collateralValue)

  const convenience = await convenienceInit(maturity, assetToken, collateralToken, signerWithAddress)
  await assetToken.approve(convenience.convenienceContract.address, assetValue)
  await collateralToken.approve(convenience.convenienceContract.address, collateralValue)

  return { convenience, assetToken, collateralToken, maturity }
}
export async function newLiquidityFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  newLiquidityParams: NewLiquidityParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.newLiquidity(
    fixture.maturity,
    fixture.assetToken.address,
    fixture.collateralToken.address,
    newLiquidityParams.assetIn,
    newLiquidityParams.debtIn,
    newLiquidityParams.collateralIn
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function newLiquidityETHAssetFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  newLiquidityParams: NewLiquidityParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.newLiquidityETHAsset(
    fixture.maturity,
    fixture.collateralToken.address,
    newLiquidityParams.assetIn,
    newLiquidityParams.debtIn,
    newLiquidityParams.collateralIn
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function newLiquidityETHCollateralFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  newLiquidityParams: NewLiquidityParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.newLiquidityETHCollateral(
    fixture.maturity,
    fixture.assetToken.address,
    newLiquidityParams.assetIn,
    newLiquidityParams.debtIn,
    newLiquidityParams.collateralIn
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function addLiquidityFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  addLiquidityParams: AddLiquidityParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.addLiquidity(
    fixture.maturity,
    fixture.assetToken.address,
    fixture.collateralToken.address,
    addLiquidityParams.assetIn,
    addLiquidityParams.minLiquidity,
    addLiquidityParams.maxDebt,
    addLiquidityParams.maxCollateral
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function addLiquidityETHAssetFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  addLiquidityParams: AddLiquidityParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.addLiquidityETHAsset(
    fixture.maturity,
    fixture.collateralToken.address,
    addLiquidityParams.assetIn,
    addLiquidityParams.minLiquidity,
    addLiquidityParams.maxDebt,
    addLiquidityParams.maxCollateral
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function addLiquidityETHCollateralFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  addLiquidityParams: AddLiquidityParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.addLiquidityETHCollateral(
    fixture.maturity,
    fixture.assetToken.address,
    addLiquidityParams.assetIn,
    addLiquidityParams.minLiquidity,
    addLiquidityParams.maxDebt,
    addLiquidityParams.maxCollateral
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function removeLiquidityFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  removeLiquidityParams: RemoveLiquidityParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.removeLiquidity(
    fixture.maturity,
    fixture.assetToken.address,
    fixture.collateralToken.address,
    removeLiquidityParams.liquidityIn
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function removeLiquidityETHAssetFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  removeLiquidityParams: RemoveLiquidityParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.removeLiquidityETHAsset(
    fixture.maturity,
    fixture.collateralToken.address,
    removeLiquidityParams.liquidityIn
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function removeLiquidityETHCollateralFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  removeLiquidityParams: RemoveLiquidityParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.removeLiquidityETHCollateral(
    fixture.maturity,
    fixture.assetToken.address,
    removeLiquidityParams.liquidityIn
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function lendGivenBondFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  lendGivenBondParams: LendGivenBondParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.lendGivenBond(
    fixture.maturity,
    fixture.assetToken.address,
    fixture.collateralToken.address,
    lendGivenBondParams.assetIn,
    lendGivenBondParams.bondOut,
    lendGivenBondParams.minInsurance
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function lendGivenBondETHAssetFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  lendGivenBondParams: LendGivenBondParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.lendGivenBondETHAsset(
    fixture.maturity,
    fixture.collateralToken.address,
    lendGivenBondParams.assetIn,
    lendGivenBondParams.bondOut,
    lendGivenBondParams.minInsurance
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function lendGivenBondETHCollateralFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  lendGivenBondParams: LendGivenBondParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.lendGivenBondETHCollateral(
    fixture.maturity,
    fixture.assetToken.address,
    lendGivenBondParams.assetIn,
    lendGivenBondParams.bondOut,
    lendGivenBondParams.minInsurance
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function lendGivenInsuranceFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  lendGivenInsuranceParams: LendGivenInsuranceParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.lendGivenInsurance(
    fixture.maturity,
    fixture.assetToken.address,
    fixture.collateralToken.address,
    lendGivenInsuranceParams.assetIn,
    lendGivenInsuranceParams.insuranceOut,
    lendGivenInsuranceParams.minBond
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function lendGivenInsuranceETHAssetFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  lendGivenInsuranceParams: LendGivenInsuranceParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.lendGivenInsuranceETHAsset(
    fixture.maturity,
    fixture.collateralToken.address,
    lendGivenInsuranceParams.assetIn,
    lendGivenInsuranceParams.insuranceOut,
    lendGivenInsuranceParams.minBond
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function lendGivenInsuranceETHCollateralFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  lendGivenInsuranceParams: LendGivenInsuranceParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.lendGivenInsuranceETHCollateral(
    fixture.maturity,
    fixture.assetToken.address,
    lendGivenInsuranceParams.assetIn,
    lendGivenInsuranceParams.insuranceOut,
    lendGivenInsuranceParams.minBond
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function lendGivenPercentFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  lendGivenPercentParams: LendGivenPercentParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.lendGivenPercent(
    fixture.maturity,
    fixture.assetToken.address,
    fixture.collateralToken.address,
    lendGivenPercentParams.assetIn,
    lendGivenPercentParams.minInsurance,
    lendGivenPercentParams.minBond,
    lendGivenPercentParams.percent,
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function lendGivenPercentETHAssetFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  lendGivenPercentParams: LendGivenPercentParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.lendGivenPercentETHAsset(
    fixture.maturity,
    fixture.collateralToken.address,
    lendGivenPercentParams.assetIn,
    lendGivenPercentParams.minInsurance,
    lendGivenPercentParams.minBond,
    lendGivenPercentParams.percent,
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function lendGivenPercentETHCollateralFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  lendGivenPercentParams: LendGivenPercentParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.lendGivenPercentETHCollateral(
    fixture.maturity,
    fixture.assetToken.address,
    lendGivenPercentParams.assetIn,
    lendGivenPercentParams.minInsurance,
    lendGivenPercentParams.minBond,
    lendGivenPercentParams.percent,
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function collectFixture(fixture: Fixture, signer: SignerWithAddress, collectParams: CollectParams) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.collect(
    fixture.maturity,
    fixture.assetToken.address,
    fixture.collateralToken.address,
    collectParams.claims
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function collectETHAssetFixture(fixture: Fixture, signer: SignerWithAddress, collectParams: CollectParams) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.collectETHAsset(
    fixture.maturity,
    fixture.collateralToken.address,
    collectParams.claims
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function collectETHCollateralFixture(fixture: Fixture, signer: SignerWithAddress, collectParams: CollectParams) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.collectETHCollateral(
    fixture.maturity,
    fixture.assetToken.address,
    collectParams.claims
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function borrowGivenDebtFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  borrowGivenDebtParams: BorrowGivenDebtParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.borrowGivenDebt(
    fixture.maturity,
    fixture.assetToken.address,
    fixture.collateralToken.address,
    borrowGivenDebtParams.assetOut,
    borrowGivenDebtParams.debtIn,
    borrowGivenDebtParams.maxCollateral
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function borrowGivenDebtETHAssetFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  borrowGivenDebtParams: BorrowGivenDebtParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.borrowGivenDebtETHAsset(
    fixture.maturity,
    fixture.collateralToken.address,
    borrowGivenDebtParams.assetOut,
    borrowGivenDebtParams.debtIn,
    borrowGivenDebtParams.maxCollateral
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function borrowGivenDebtETHCollateralFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  borrowGivenDebtParams: BorrowGivenDebtParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.borrowGivenDebtETHCollateral(
    fixture.maturity,
    fixture.assetToken.address,
    borrowGivenDebtParams.assetOut,
    borrowGivenDebtParams.debtIn,
    borrowGivenDebtParams.maxCollateral
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function borrowGivenCollateralFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  borrowGivenCollateralParams: BorrowGivenCollateralParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.borrowGivenCollateral(
    fixture.maturity,
    fixture.assetToken.address,
    fixture.collateralToken.address,
    borrowGivenCollateralParams.assetOut,
    borrowGivenCollateralParams.maxDebt,
    borrowGivenCollateralParams.collateralIn
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function borrowGivenCollateralETHAssetFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  borrowGivenCollateralParams: BorrowGivenCollateralParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.borrowGivenCollateralETHAsset(
    fixture.maturity,
    fixture.collateralToken.address,
    borrowGivenCollateralParams.assetOut,
    borrowGivenCollateralParams.maxDebt,
    borrowGivenCollateralParams.collateralIn
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function borrowGivenCollateralETHCollateralFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  borrowGivenCollateralParams: BorrowGivenCollateralParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.borrowGivenCollateralETHCollateral(
    fixture.maturity,
    fixture.assetToken.address,
    borrowGivenCollateralParams.assetOut,
    borrowGivenCollateralParams.maxDebt,
    borrowGivenCollateralParams.collateralIn
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function borrowGivenPercentFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  borrowGivenPercentParams: BorrowGivenPercentParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.borrowGivenPercent(
    fixture.maturity,
    fixture.assetToken.address,
    fixture.collateralToken.address,
    borrowGivenPercentParams.assetOut,
    borrowGivenPercentParams.maxDebt,
    borrowGivenPercentParams.maxCollateral,
    borrowGivenPercentParams.percent
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function borrowGivenPercentETHAssetFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  borrowGivenPercentParams: BorrowGivenPercentParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.borrowGivenPercentETHAsset(
    fixture.maturity,
    fixture.collateralToken.address,
    borrowGivenPercentParams.assetOut,
    borrowGivenPercentParams.maxDebt,
    borrowGivenPercentParams.maxCollateral,
    borrowGivenPercentParams.percent
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function borrowGivenPercentETHCollateralFixture(
  fixture: Fixture,
  signer: SignerWithAddress,
  borrowGivenPercentParams: BorrowGivenPercentParams
) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.borrowGivenPercentETHCollateral(
    fixture.maturity,
    fixture.assetToken.address,
    borrowGivenPercentParams.assetOut,
    borrowGivenPercentParams.maxDebt,
    borrowGivenPercentParams.maxCollateral,
    borrowGivenPercentParams.percent
  )
  await txn.wait()

  return { convenience, assetToken, collateralToken, maturity }
}
export async function repayFixture(fixture: Fixture, signer: SignerWithAddress, repayParams: RepayParams) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.repay(
    fixture.maturity,
    fixture.assetToken.address,
    fixture.collateralToken.address,
    repayParams.ids,
    repayParams.maxAssetsIn
  )

  return { convenience, assetToken, collateralToken, maturity }
}

export async function repayETHAssetFixture(fixture: Fixture, signer: SignerWithAddress, repayParams: RepayParams) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.repayETHAsset(
    fixture.maturity,
    fixture.collateralToken.address,
    repayParams.ids,
    repayParams.maxAssetsIn
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function repayETHCollateralFixture(fixture: Fixture, signer: SignerWithAddress, repayParams: RepayParams) {
  const { convenience, assetToken, collateralToken, maturity } = fixture
  const txn = await fixture.convenience.repayETHCollateral(
    fixture.maturity,
    fixture.assetToken.address,
    repayParams.ids,
    repayParams.maxAssetsIn
  )

  return { convenience, assetToken, collateralToken, maturity }
}
export async function mintMathCalleeGivenNewFixture(fixture:Fixture, signer:SignerWithAddress,newLiqudityParams: NewLiquidityParams){
  const {convenience, assetToken, collateralToken, maturity} = fixture
  const mintMathCalleeFactory =await  ethers.getContractFactory('MintMathCallee')
  const mintMathCalleeContract = (await (mintMathCalleeFactory).deploy()) as MintMathCallee
  const txn = await mintMathCalleeContract.givenNew(maturity,newLiqudityParams.assetIn,newLiqudityParams.debtIn,newLiqudityParams.collateralIn);
  return txn
}
export async function mintMathCalleeGivenAddFixture(fixture:Fixture, signer:SignerWithAddress,addLiquidityParams: AddLiquidityParams){
  const {convenience, assetToken, collateralToken, maturity} = fixture
  const mintMathCalleeFactory =await  ethers.getContractFactory('MintMathCallee')
  const mintMathCalleeContract = (await (mintMathCalleeFactory).deploy()) as MintMathCallee
  const pair = (await convenience.factoryContract.getPair(assetToken.address,collateralToken.address))
  const txn = await mintMathCalleeContract.givenAdd(pair,maturity,addLiquidityParams.assetIn);
  return txn
}
export async function lendMathGivenBondFixture(fixture:Fixture,signer:SignerWithAddress,lendGivenBondParams: LendGivenBondParams) {
  const {convenience, assetToken, collateralToken, maturity} = fixture
  const lendMathCalleeFactory =await  ethers.getContractFactory('LendMathCallee')
  const lendMathCalleeContract = (await (lendMathCalleeFactory).deploy()) as LendMathCallee
  const pair = (await convenience.factoryContract.getPair(assetToken.address,collateralToken.address))
  const txn = await lendMathCalleeContract.givenBond(pair,maturity,lendGivenBondParams.assetIn,lendGivenBondParams.bondOut)
  return txn

}
export async function lendMathGivenInsuranceFixture(fixture:Fixture,signer:SignerWithAddress,lendGivenInsuranceParams: LendGivenInsuranceParams) {
  const {convenience, assetToken, collateralToken, maturity} = fixture
  const lendMathCalleeFactory =await  ethers.getContractFactory('LendMathCallee')
  const lendMathCalleeContract = (await (lendMathCalleeFactory).deploy()) as LendMathCallee
  const pair = (await convenience.factoryContract.getPair(assetToken.address,collateralToken.address))
  const txn = await lendMathCalleeContract.givenInsurance(pair,maturity,lendGivenInsuranceParams.assetIn,lendGivenInsuranceParams.insuranceOut)
  return txn

}
export async function lendMathGivenPercentFixture(fixture:Fixture,signer:SignerWithAddress,lendGivenPercentParams: LendGivenPercentParams) {
  const {convenience, assetToken, collateralToken, maturity} = fixture
  const lendMathCalleeFactory =await  ethers.getContractFactory('LendMathCallee')
  const lendMathCalleeContract = (await (lendMathCalleeFactory).deploy()) as LendMathCallee
  const pair = (await convenience.factoryContract.getPair(assetToken.address,collateralToken.address))
  const txn = await lendMathCalleeContract.givenPercent(pair,maturity,lendGivenPercentParams.assetIn,lendGivenPercentParams.percent)
  return txn

}
export async function borrowMathGivenDebtFixture(fixture:Fixture,signer:SignerWithAddress,borrowGivenDebt: BorrowGivenDebtParams) {
  const {convenience, assetToken, collateralToken, maturity} = fixture
  const borrowMathCalleeFactory =await  ethers.getContractFactory('BorrowMathCallee')
  const borrowMathCalleeContract = (await (borrowMathCalleeFactory).deploy()) as BorrowMathCallee
  const pair = (await convenience.factoryContract.getPair(assetToken.address,collateralToken.address))
  const txn = await borrowMathCalleeContract.givenDebt(pair,maturity,borrowGivenDebt.assetOut,borrowGivenDebt.debtIn)
  return txn

}
export async function borrowMathGivenCollateralFixture(fixture:Fixture,signer:SignerWithAddress,borrowGivenCollateral: BorrowGivenCollateralParams) {
  const {convenience, assetToken, collateralToken, maturity} = fixture
  const borrowMathCalleeFactory =await  ethers.getContractFactory('BorrowMathCallee')
  const borrowMathCalleeContract = (await (borrowMathCalleeFactory).deploy()) as BorrowMathCallee
  const pair = (await convenience.factoryContract.getPair(assetToken.address,collateralToken.address))
  const txn = await borrowMathCalleeContract.givenCollateral(pair,maturity,borrowGivenCollateral.assetOut,borrowGivenCollateral.collateralIn)
  return txn
}
export async function borrowMathGivenPercentFixture(fixture:Fixture,signer:SignerWithAddress,borrowGivenPercent: BorrowGivenPercentParams) {
  const {convenience, assetToken, collateralToken, maturity} = fixture
  const borrowMathCalleeFactory =await  ethers.getContractFactory('BorrowMathCallee')
  const borrowMathCalleeContract = (await (borrowMathCalleeFactory).deploy()) as BorrowMathCallee
  const pair = (await convenience.factoryContract.getPair(assetToken.address,collateralToken.address))
  const txn = await borrowMathCalleeContract.givenPercent(pair,maturity,borrowGivenPercent.assetOut,borrowGivenPercent.percent)
  return txn

}
export interface Fixture {
  convenience: Convenience
  assetToken: TestToken
  collateralToken: TestToken
  maturity: bigint
}
