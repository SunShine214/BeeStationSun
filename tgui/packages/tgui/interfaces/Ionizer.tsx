import { useBackend } from 'tgui/backend';

import { Button, Flex, Knob, Section } from '../components';
import { Window } from '../layouts';

type Data = {
  reaction_gas: string;
  ion_agent_gas: string;
  efficiency: number;
  ratio: number;
  ionizer_gases: IonizerGas[];
};

type IonizerGas = {
  gas: string;
  ion_agents: string[];
};

export const Ionizer = (props) => {
  const { act, data } = useBackend<Data>();
  const { reaction_gas, ion_agent_gas, efficiency, ratio, ionizer_gases } =
    data;
  return (
    <Window width={480} height={500}>
      <Window.Content>
        <Section title="Ionizer" fill={1} overflow-y="scroll">
          {efficiency}
          <Flex>
            {ionizer_gases.map((gas: IonizerGas) => (
              <Flex.Item key={gas.gas}>
                <Button content={gas.gas} selected={gas.gas === reaction_gas} />
              </Flex.Item>
            ))}
          </Flex>
          <Knob
            size={1.25}
            color={'yellow'}
            value={ratio}
            unit=""
            format={(i) => {
              return i.toFixed(1);
            }}
            minValue={0.1}
            maxValue={1}
            step={0.1}
            stepPixelSize={5}
            onDrag={(e, value) =>
              act('change_ratio', {
                ratio: value,
              })
            }
          />
        </Section>
      </Window.Content>
    </Window>
  );
};
