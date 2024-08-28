#!/bin/sh

echo 'Generating '$2'.xml......'
echo '<Entities xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="EntitiesSchema.xsd">
    <Entity>
        <PublishCertificatetoTDPS>true</PublishCertificatetoTDPS>
        <EntityProfile Name="DUSGen2OAM_CHAIN_EP" />

        <KeyGenerationAlgorithm>
            <Name>RSA</Name>
            <KeySize>2048</KeySize>
        </KeyGenerationAlgorithm>
        <Category>
            <Modifiable>true</Modifiable>
            <Name>UNDEFINED</Name>
        </Category>
        <EntityInfo>
            <Name>'$2'</Name>

            <Subject>
                <SubjectField>
                    <Type>COMMON_NAME</Type>
                    <Value>'$1'</Value>
				</SubjectField>
				<SubjectField>
				<Type>ORGANIZATION_UNIT</Type>
					<Value>TCS</Value>
					</SubjectField>
					<SubjectField>
					<Type>COUNTRY_NAME</Type>
					<Value>IN</Value>
					</SubjectField>
					<SubjectField>
					<Type>ORGANIZATION</Type>
					<Value>ERICSSON</Value>
                </SubjectField>
            </Subject>
        </EntityInfo>
    </Entity>
</Entities>' > $2.xml
echo 'done'
