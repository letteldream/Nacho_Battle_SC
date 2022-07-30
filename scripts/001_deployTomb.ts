import { ethers } from 'hardhat'

async function main(): Promise<string> {
  const [deployer] = await ethers.getSigners()
  if (deployer === undefined) throw new Error('Deployer is undefined.')

  console.log('Account balance:', (await deployer.getBalance()).toString())

  const _taxRate = 100
  const _taxCollectorAddress = '0xb5D774a16CF9903353DaeAE188a1954312080D4a'

  const Tomb = await ethers.getContractFactory('Tomb')
  const Tomb_Deployed = await Tomb.deploy(_taxRate, _taxCollectorAddress)

  return Tomb_Deployed.address
}

main()
  .then((r: string) => {
    console.log('deployed address:', r)
    return r
  })
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
